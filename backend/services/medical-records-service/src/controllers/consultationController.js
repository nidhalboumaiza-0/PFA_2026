import Consultation from '../models/Consultation.js';
import { kafkaProducer, TOPICS, createEvent, sendError, sendSuccess } from '../../../../shared/index.js';
import {
  fetchAppointmentDetails,
  fetchPatientProfile,
  hasDoctorTreatedPatient,
  getPatientBasicInfo,
  getDoctorBasicInfo,
  buildDateRangeQuery,
  calculatePagination,
  formatConsultationForTimeline,
  formatConsultationForPatient,
  createAuditLog
} from '../utils/consultationHelpers.js';

/**
 * Create Consultation
 * POST /api/v1/medical/consultations
 */
export const createConsultation = async (req, res, next) => {
  try {
    const { id: doctorId } = req.user;
    const {
      appointmentId,
      chiefComplaint,
      medicalNote,
      consultationType,
      requiresFollowUp,
      followUpDate,
      followUpNotes,
      isFromReferral,
      referralId,
      status
    } = req.body;

    // Get auth token from request
    const authToken = req.headers.authorization?.split(' ')[1];

    // Verify appointment exists and is completed
    const appointment = await fetchAppointmentDetails(appointmentId, authToken);

    if (appointment.status !== 'completed') {
      return sendError(res, 400, 'INVALID_APPOINTMENT_STATUS',
        'Consultation can only be created for completed appointments.');
    }

    // Verify doctor owns this appointment
    if (appointment.doctorId.toString() !== doctorId.toString()) {
      return sendError(res, 403, 'FORBIDDEN',
        'You can only create consultations for your own appointments.');
    }

    // Check if consultation already exists for this appointment
    const existingConsultation = await Consultation.findOne({ appointmentId });
    if (existingConsultation) {
      return sendError(res, 409, 'CONSULTATION_EXISTS',
        'Consultation already exists for this appointment.');
    }

    // Create consultation
    const consultation = await Consultation.create({
      appointmentId,
      patientId: appointment.patientId,
      doctorId,
      consultationDate: appointment.appointmentDate,
      consultationType: consultationType || 'in-person',
      chiefComplaint,
      medicalNote,
      requiresFollowUp: requiresFollowUp || false,
      followUpDate,
      followUpNotes,
      isFromReferral: isFromReferral || false,
      referralId,
      status: status || 'completed',
      createdBy: doctorId,
      lastModifiedBy: doctorId
    });

    // Publish Kafka event
    await kafkaProducer.sendEvent(
      TOPICS.MEDICAL.CONSULTATION_CREATED,
      createEvent('consultation.created', {
        consultationId: consultation._id.toString(),
        appointmentId: appointmentId.toString(),
        patientId: appointment.patientId.toString(),
        doctorId: doctorId.toString(),
        consultationDate: consultation.consultationDate,
        diagnosis: medicalNote.diagnosis
      })
    );

    res.status(201).json({
      message: 'Consultation created successfully',
      consultation
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Get Consultation by ID
 * GET /api/v1/medical/consultations/:consultationId
 */
export const getConsultationById = async (req, res, next) => {
  try {
    const { id: userId, role } = req.user;
    const { consultationId } = req.params;

    const consultation = await Consultation.findById(consultationId);

    if (!consultation) {
      return sendError(res, 404, 'CONSULTATION_NOT_FOUND',
        'The consultation you are looking for does not exist.');
    }

    // Verify access
    if (role === 'patient') {
      if (consultation.patientId.toString() !== userId.toString()) {
        return sendError(res, 403, 'FORBIDDEN',
          'You can only view your own consultations.');
      }
    } else if (role === 'doctor') {
      const hasAccess = await consultation.canDoctorAccess(userId);
      if (!hasAccess) {
        return sendError(res, 403, 'FORBIDDEN',
          'You can only view consultations for patients you have treated.');
      }
    }

    // Publish audit event
    await kafkaProducer.sendEvent(
      TOPICS.MEDICAL.CONSULTATION_ACCESSED,
      createEvent('consultation.accessed', {
        consultationId: consultation._id.toString(),
        accessedBy: userId.toString(),
        accessType: 'basic_view'
      })
    );

    res.status(200).json({
      consultation
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Update Consultation
 * PUT /api/v1/medical/consultations/:consultationId
 */
export const updateConsultation = async (req, res, next) => {
  try {
    const { id: doctorId } = req.user;
    const { consultationId } = req.params;
    const updates = req.body;

    const consultation = await Consultation.findById(consultationId);

    if (!consultation) {
      return sendError(res, 404, 'CONSULTATION_NOT_FOUND',
        'The consultation you are looking for does not exist.');
    }

    // Verify doctor owns this consultation
    if (consultation.doctorId.toString() !== doctorId.toString()) {
      return sendError(res, 403, 'FORBIDDEN',
        'You can only update your own consultations.');
    }

    // Check if consultation can be modified (24-hour rule)
    if (!consultation.canBeModified()) {
      return sendError(res, 400, 'CONSULTATION_LOCKED',
        'Consultation cannot be modified after 24 hours or if archived.');
    }

    // Track changed fields
    const changedFields = Object.keys(updates);

    // Update consultation
    if (updates.medicalNote) {
      consultation.medicalNote = {
        ...consultation.medicalNote,
        ...updates.medicalNote
      };
    }

    if (updates.requiresFollowUp !== undefined) {
      consultation.requiresFollowUp = updates.requiresFollowUp;
    }

    if (updates.followUpDate) {
      consultation.followUpDate = updates.followUpDate;
    }

    if (updates.followUpNotes) {
      consultation.followUpNotes = updates.followUpNotes;
    }

    if (updates.status) {
      consultation.status = updates.status;
    }

    consultation.lastModifiedBy = doctorId;
    await consultation.save();

    // Publish Kafka event
    await kafkaProducer.sendEvent(
      TOPICS.MEDICAL.CONSULTATION_UPDATED,
      createEvent('consultation.updated', {
        consultationId: consultation._id.toString(),
        updatedBy: doctorId.toString(),
        changes: changedFields
      })
    );

    res.status(200).json({
      message: 'Consultation updated successfully',
      consultation
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Get Consultation Full Details
 * GET /api/v1/medical/consultations/:consultationId/full
 */
export const getConsultationFullDetails = async (req, res, next) => {
  try {
    const { id: doctorId } = req.user;
    const { consultationId } = req.params;

    const consultation = await Consultation.findById(consultationId);

    if (!consultation) {
      return sendError(res, 404, 'CONSULTATION_NOT_FOUND',
        'The consultation you are looking for does not exist.');
    }

    // Verify doctor has access
    const hasAccess = await consultation.canDoctorAccess(doctorId);
    if (!hasAccess) {
      return sendError(res, 403, 'FORBIDDEN',
        'You can only view consultations for patients you have treated.');
    }

    // Fetch patient full profile
    const patient = await fetchPatientProfile(consultation.patientId);

    // Fetch doctor info
    const doctor = await getDoctorBasicInfo(consultation.doctorId);

    // Get previous consultations summary
    const previousConsultations = await Consultation.find({
      patientId: consultation.patientId,
      _id: { $ne: consultation._id },
      status: { $in: ['completed', 'archived'] }
    })
      .sort({ consultationDate: -1 })
      .limit(5)
      .select('consultationDate doctorId medicalNote.diagnosis');

    const previousConsultationsSummary = await Promise.all(
      previousConsultations.map(async (c) => {
        const prevDoctor = await getDoctorBasicInfo(c.doctorId);
        return {
          id: c._id,
          date: c.consultationDate,
          doctor: prevDoctor.name,
          diagnosis: c.medicalNote?.diagnosis || 'Not specified'
        };
      })
    );

    // Publish audit event
    await kafkaProducer.sendEvent(
      TOPICS.MEDICAL.CONSULTATION_ACCESSED,
      createEvent('consultation.accessed', {
        consultationId: consultation._id.toString(),
        accessedBy: doctorId.toString(),
        accessType: 'full_view'
      })
    );

    res.status(200).json({
      consultation: {
        id: consultation._id,
        date: consultation.consultationDate,
        type: consultation.consultationType,
        chiefComplaint: consultation.chiefComplaint,
        medicalNote: consultation.medicalNote,
        requiresFollowUp: consultation.requiresFollowUp,
        followUpDate: consultation.followUpDate,
        followUpNotes: consultation.followUpNotes,
        status: consultation.status,
        doctor
      },
      patient: {
        id: patient._id,
        name: patient.fullName || `${patient.firstName} ${patient.lastName}`,
        age: patient.age,
        gender: patient.gender,
        bloodType: patient.bloodType,
        allergies: patient.allergies || [],
        chronicDiseases: patient.chronicDiseases || []
      },
      prescription: consultation.prescriptionId || null,
      documents: consultation.documentIds || [],
      previousConsultations: previousConsultationsSummary
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Get Patient Medical Timeline
 * GET /api/v1/medical/patients/:patientId/timeline
 */
export const getPatientTimeline = async (req, res, next) => {
  try {
    const { id: doctorId } = req.user;
    const { patientId } = req.params;
    const { startDate, endDate, doctorId: filterDoctorId, page, limit } = req.query;

    // Build query
    const query = {
      patientId,
      status: { $in: ['completed', 'archived'] }
    };

    // Add date range filter
    Object.assign(query, buildDateRangeQuery(startDate, endDate));

    // Add doctor filter if specified
    if (filterDoctorId) {
      query.doctorId = filterDoctorId;
    }

    // Get total count
    const totalConsultations = await Consultation.countDocuments(query);

    // Calculate pagination
    const { skip, pagination } = calculatePagination(page, limit, totalConsultations);

    // Get consultations
    const consultations = await Consultation.find(query)
      .sort({ consultationDate: -1 })
      .skip(skip)
      .limit(limit);

    // Format timeline
    const timeline = await Promise.all(
      consultations.map(c => formatConsultationForTimeline(c))
    );

    // Get patient basic info
    const patient = await getPatientBasicInfo(patientId);

    res.status(200).json({
      patient,
      timeline,
      pagination
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Search Patient History
 * GET /api/v1/medical/patients/:patientId/search
 */
export const searchPatientHistory = async (req, res, next) => {
  try {
    const { id: doctorId } = req.user;
    const { patientId } = req.params;
    const { keyword, diagnosis, dateFrom, dateTo, page, limit } = req.query;

    // Build query
    const query = {
      patientId,
      status: { $in: ['completed', 'archived'] }
    };

    // Text search
    if (keyword) {
      query.$text = { $search: keyword };
    }

    // Diagnosis search
    if (diagnosis) {
      query['medicalNote.diagnosis'] = { $regex: diagnosis, $options: 'i' };
    }

    // Date range
    Object.assign(query, buildDateRangeQuery(dateFrom, dateTo));

    // Get total count
    const totalResults = await Consultation.countDocuments(query);

    // Calculate pagination
    const { skip, pagination } = calculatePagination(page, limit, totalResults);

    // Execute search
    const consultations = await Consultation.find(query)
      .sort({ consultationDate: -1 })
      .skip(skip)
      .limit(limit);

    // Format results
    const results = await Promise.all(
      consultations.map(c => formatConsultationForTimeline(c))
    );

    // Publish audit event
    await kafkaProducer.sendEvent(
      TOPICS.MEDICAL.CONSULTATION_ACCESSED,
      createEvent('consultation.searched', {
        patientId: patientId.toString(),
        searchedBy: doctorId.toString(),
        searchParams: { keyword, diagnosis }
      })
    );

    res.status(200).json({
      results,
      pagination
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Get Doctor's Consultation History
 * GET /api/v1/medical/doctors/my-consultations
 */
export const getDoctorConsultations = async (req, res, next) => {
  try {
    const { id: doctorId } = req.user;
    const { startDate, endDate, page, limit } = req.query;

    // Build query
    const query = {
      doctorId,
      status: { $in: ['completed', 'archived'] }
    };

    // Add date range
    Object.assign(query, buildDateRangeQuery(startDate, endDate));

    // Get total count
    const totalConsultations = await Consultation.countDocuments(query);

    // Calculate pagination
    const { skip, pagination } = calculatePagination(page, limit, totalConsultations);

    // Get consultations
    const consultations = await Consultation.find(query)
      .sort({ consultationDate: -1 })
      .skip(skip)
      .limit(limit);

    // Populate patient info
    const consultationsWithPatients = await Promise.all(
      consultations.map(async (c) => {
        const patient = await getPatientBasicInfo(c.patientId);
        return {
          id: c._id,
          date: c.consultationDate,
          patient,
          chiefComplaint: c.chiefComplaint,
          diagnosis: c.medicalNote?.diagnosis || 'Not specified',
          status: c.status
        };
      })
    );

    res.status(200).json({
      consultations: consultationsWithPatients,
      pagination
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Patient: View My Medical History
 * GET /api/v1/medical/patients/my-history
 */
export const getMyMedicalHistory = async (req, res, next) => {
  try {
    const { id: patientId } = req.user;
    const { page, limit } = req.query;

    const query = {
      patientId,
      status: { $in: ['completed', 'archived'] }
    };

    // Get total count
    const totalConsultations = await Consultation.countDocuments(query);

    // Calculate pagination
    const { skip, pagination } = calculatePagination(
      page || 1,
      limit || 20,
      totalConsultations
    );

    // Get consultations
    const consultations = await Consultation.find(query)
      .sort({ consultationDate: -1 })
      .skip(skip)
      .limit(limit || 20);

    // Format for patient view
    const history = await Promise.all(
      consultations.map(c => formatConsultationForPatient(c))
    );

    res.status(200).json({
      history,
      pagination
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Get Consultation Statistics
 * GET /api/v1/medical/statistics/consultations
 */
export const getConsultationStatistics = async (req, res, next) => {
  try {
    const { id: doctorId } = req.user;

    const now = new Date();
    const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const startOfWeek = new Date(startOfDay);
    startOfWeek.setDate(startOfWeek.getDate() - startOfWeek.getDay());
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

    // Total consultations
    const totalConsultations = await Consultation.countDocuments({ doctorId });

    // Today's consultations
    const today = await Consultation.countDocuments({
      doctorId,
      consultationDate: { $gte: startOfDay }
    });

    // This week's consultations
    const thisWeek = await Consultation.countDocuments({
      doctorId,
      consultationDate: { $gte: startOfWeek }
    });

    // This month's consultations
    const thisMonth = await Consultation.countDocuments({
      doctorId,
      consultationDate: { $gte: startOfMonth }
    });

    // Common diagnoses
    const commonDiagnoses = await Consultation.aggregate([
      {
        $match: {
          doctorId: doctorId,
          'medicalNote.diagnosis': { $exists: true, $ne: '' }
        }
      },
      {
        $group: {
          _id: '$medicalNote.diagnosis',
          count: { $sum: 1 }
        }
      },
      { $sort: { count: -1 } },
      { $limit: 10 },
      {
        $project: {
          _id: 0,
          diagnosis: '$_id',
          count: 1
        }
      }
    ]);

    res.status(200).json({
      statistics: {
        totalConsultations,
        today,
        thisWeek,
        thisMonth,
        commonDiagnoses
      }
    });
  } catch (error) {
    next(error);
  }
};
