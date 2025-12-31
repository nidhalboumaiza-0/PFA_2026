import Referral from '../models/Referral.js';
import { kafkaProducer, TOPICS, createEvent, sendError, sendSuccess } from '../../../../shared/index.js';
import {
  getUserInfo,
  getDoctorInfo,
  getPatientInfo,
  hasDoctorTreatedPatient,
  verifyDoctorSpecialty,
  searchSpecialists,
  checkDoctorAvailability,
  createReferralAppointment,
  cancelAppointment,
  getAppointmentDetails,
  getDocumentDetails,
  verifyDocumentsOwnership,
  formatReferralForResponse,
  calculatePagination,
  buildDateRangeQuery,
  formatSpecialistInfo
} from '../utils/referralHelpers.js';

/**
 * Create Referral
 * POST /api/v1/referrals
 */
export const createReferral = async (req, res, next) => {
  try {
    const { id: referringDoctorId } = req.user;
    const {
      patientId,
      targetDoctorId,
      reason,
      urgency,
      specialty,
      diagnosis,
      symptoms,
      relevantHistory,
      currentMedications,
      specificConcerns,
      attachedDocuments,
      includeFullHistory,
      preferredDates,
      referralNotes
    } = req.body;

    // Validate patient exists
    const patient = await getPatientInfo(patientId);
    if (!patient) {
      return sendError(res, 404, 'PATIENT_NOT_FOUND',
        'The patient you are looking for does not exist.');
    }

    // Verify doctor has treated patient
    const hasTreated = await hasDoctorTreatedPatient(referringDoctorId, patientId);
    if (!hasTreated) {
      return sendError(res, 403, 'FORBIDDEN',
        'You can only refer patients you have treated.');
    }

    // Validate target doctor exists
    const targetDoctor = await getDoctorInfo(targetDoctorId);
    if (!targetDoctor) {
      return sendError(res, 404, 'DOCTOR_NOT_FOUND',
        'The target doctor does not exist.');
    }

    // Verify target doctor is active and verified
    if (!targetDoctor.isVerified || !targetDoctor.isActive) {
      return sendError(res, 400, 'DOCTOR_NOT_AVAILABLE',
        'Target doctor is not available for referrals.');
    }

    // Verify specialty matches
    if (targetDoctor.specialty.toLowerCase() !== specialty.toLowerCase()) {
      return sendError(res, 400, 'SPECIALTY_MISMATCH',
        `Target doctor specialty (${targetDoctor.specialty}) does not match requested specialty (${specialty}).`);
    }

    // Verify attached documents belong to patient
    if (attachedDocuments && attachedDocuments.length > 0) {
      const documentsValid = await verifyDocumentsOwnership(
        attachedDocuments,
        patientId,
        req.headers.authorization
      );
      if (!documentsValid) {
        return sendError(res, 400, 'INVALID_DOCUMENTS',
          'One or more attached documents do not belong to this patient.');
      }
    }

    // Create referral
    const referral = await Referral.create({
      referringDoctorId,
      targetDoctorId,
      patientId,
      reason,
      urgency: urgency || 'routine',
      specialty,
      diagnosis,
      symptoms,
      relevantHistory,
      currentMedications,
      specificConcerns,
      attachedDocuments: attachedDocuments || [],
      includeFullHistory: includeFullHistory !== false,
      preferredDates: preferredDates || [],
      referralNotes,
      status: 'pending'
    });

    // Add to status history
    referral.addStatusHistory('pending', referringDoctorId, 'Referral created');
    await referral.save();

    // Publish Kafka event
    await kafkaProducer.sendEvent(
      TOPICS.REFERRAL.REFERRAL_CREATED,
      createEvent('referral.created', {
        referralId: referral._id.toString(),
        referringDoctorId: referringDoctorId.toString(),
        targetDoctorId: targetDoctorId.toString(),
        patientId: patientId.toString(),
        urgency: referral.urgency,
        specialty: referral.specialty
      })
    );

    res.status(201).json({
      message: 'Referral created successfully. Target doctor will be notified.',
      referral: {
        id: referral._id,
        targetDoctor: {
          id: targetDoctor._id,
          name: `Dr. ${targetDoctor.firstName} ${targetDoctor.lastName}`,
          specialty: targetDoctor.specialty
        },
        patient: {
          id: patient._id,
          name: `${patient.firstName} ${patient.lastName}`
        },
        status: referral.status,
        urgency: referral.urgency,
        expiryDate: referral.expiryDate
      }
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Get Referral Details
 * GET /api/v1/referrals/:referralId
 */
export const getReferralById = async (req, res, next) => {
  try {
    const { id: userId, role } = req.user;
    const { referralId } = req.params;

    const referral = await Referral.findById(referralId);

    if (!referral) {
      return sendError(res, 404, 'REFERRAL_NOT_FOUND',
        'The referral you are looking for does not exist.');
    }

    // Verify access
    if (!referral.canUserView(userId, role)) {
      return sendError(res, 403, 'FORBIDDEN',
        'You do not have access to this referral.');
    }

    // Get related information
    const [referringDoctor, targetDoctor, patient] = await Promise.all([
      getDoctorInfo(referral.referringDoctorId),
      getDoctorInfo(referral.targetDoctorId),
      getPatientInfo(referral.patientId)
    ]);

    // Get appointment details if booked
    let appointment = null;
    if (referral.appointmentId) {
      appointment = await getAppointmentDetails(referral.appointmentId);
    }

    // Get attached documents
    let attachedDocuments = [];
    if (referral.attachedDocuments.length > 0) {
      attachedDocuments = await Promise.all(
        referral.attachedDocuments.map(docId =>
          getDocumentDetails(docId, req.headers.authorization)
        )
      );
      attachedDocuments = attachedDocuments.filter(doc => doc !== null);
    }

    // Format status history
    const statusHistory = await Promise.all(
      referral.statusHistory.map(async (entry) => {
        const user = await getUserInfo(entry.updatedBy, req.headers.authorization);
        return {
          status: entry.status,
          timestamp: entry.timestamp,
          updatedBy: user ? `${user.firstName} ${user.lastName}` : 'Unknown',
          notes: entry.notes
        };
      })
    );

    // Publish audit event
    await kafkaProducer.sendEvent(
      TOPICS.AUDIT.ACTION_LOGGED,
      createEvent('referral.viewed', {
        referralId: referral._id.toString(),
        viewedBy: userId.toString(),
        viewerRole: role
      })
    );

    res.status(200).json({
      referral: {
        id: referral._id,
        referralDate: referral.referralDate,
        status: referral.status,
        urgency: referral.urgency,
        specialty: referral.specialty,
        referringDoctor: {
          id: referringDoctor._id,
          name: `Dr. ${referringDoctor.firstName} ${referringDoctor.lastName}`,
          specialty: referringDoctor.specialty
        },
        targetDoctor: {
          id: targetDoctor._id,
          name: `Dr. ${targetDoctor.firstName} ${targetDoctor.lastName}`,
          specialty: targetDoctor.specialty
        },
        patient: {
          id: patient._id,
          name: `${patient.firstName} ${patient.lastName}`,
          age: patient.age || null
        },
        reason: referral.reason,
        diagnosis: referral.diagnosis,
        symptoms: referral.symptoms,
        relevantHistory: referral.relevantHistory,
        currentMedications: referral.currentMedications,
        specificConcerns: referral.specificConcerns,
        referralNotes: referral.referralNotes,
        responseNotes: referral.responseNotes,
        feedback: referral.feedback,
        attachedDocuments: attachedDocuments.map(doc => ({
          id: doc.id,
          title: doc.title,
          type: doc.documentType,
          signedUrl: doc.signedUrl
        })),
        appointment: appointment ? {
          id: appointment._id,
          date: appointment.appointmentDate,
          time: appointment.appointmentTime,
          status: appointment.status
        } : null,
        statusHistory,
        expiryDate: referral.expiryDate,
        createdAt: referral.createdAt
      }
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Search Specialists
 * GET /api/v1/referrals/search-specialists
 */
export const searchSpecialistsForReferral = async (req, res, next) => {
  try {
    const {
      specialty,
      city,
      latitude,
      longitude,
      radius,
      availableAfter,
      page,
      limit
    } = req.query;

    // Search specialists
    const specialists = await searchSpecialists({
      specialty,
      city,
      latitude: latitude ? parseFloat(latitude) : null,
      longitude: longitude ? parseFloat(longitude) : null,
      radius: radius ? parseInt(radius) : 10,
      availableAfter
    });

    // Format results
    const formattedSpecialists = specialists.map(doctor =>
      formatSpecialistInfo(doctor, doctor.distance)
    );

    // Paginate
    const { skip, limit: itemsPerPage, pagination } = calculatePagination(
      page,
      limit,
      formattedSpecialists.length
    );

    const paginatedResults = formattedSpecialists.slice(skip, skip + itemsPerPage);

    res.status(200).json({
      specialists: paginatedResults,
      pagination
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Book Appointment for Referral
 * POST /api/v1/referrals/:referralId/book-appointment
 */
export const bookAppointmentForReferral = async (req, res, next) => {
  try {
    const { id: referringDoctorId } = req.user;
    const { referralId } = req.params;
    const { appointmentDate, appointmentTime, notes } = req.body;

    const referral = await Referral.findById(referralId);

    if (!referral) {
      return sendError(res, 404, 'REFERRAL_NOT_FOUND',
        'The referral you are looking for does not exist.');
    }

    // Verify ownership
    if (!referral.canUserUpdate(referringDoctorId)) {
      return sendError(res, 403, 'FORBIDDEN',
        'You can only book appointments for referrals you created.');
    }

    // Check referral status
    if (!['pending', 'accepted'].includes(referral.status)) {
      return sendError(res, 400, 'INVALID_STATUS',
        `Cannot book appointment. Referral status is: ${referral.status}`);
    }

    // Check if appointment already booked
    if (referral.isAppointmentBooked) {
      return sendError(res, 400, 'APPOINTMENT_EXISTS',
        'Appointment already booked for this referral.');
    }

    // Check doctor availability
    const isAvailable = await checkDoctorAvailability(
      referral.targetDoctorId,
      appointmentDate,
      appointmentTime
    );

    if (!isAvailable) {
      return sendError(res, 400, 'SLOT_NOT_AVAILABLE',
        'Target doctor is not available at the specified date and time.');
    }

    // Create appointment
    const appointment = await createReferralAppointment(
      {
        patientId: referral.patientId,
        targetDoctorId: referral.targetDoctorId,
        referringDoctorId,
        referralId: referral._id,
        appointmentDate,
        appointmentTime,
        notes
      },
      req.headers.authorization
    );

    if (!appointment) {
      return res.status(500).json({
        message: 'Failed to create appointment'
      });
    }

    // Update referral
    referral.appointmentId = appointment._id;
    referral.isAppointmentBooked = true;
    referral.status = 'scheduled';
    referral.addStatusHistory(
      'scheduled',
      referringDoctorId,
      `Appointment booked for ${appointmentDate} at ${appointmentTime}`
    );
    await referral.save();

    // Get target doctor info
    const targetDoctor = await getDoctorInfo(referral.targetDoctorId);

    // Publish Kafka events
    await kafkaProducer.sendEvent(
      TOPICS.REFERRAL.REFERRAL_SCHEDULED,
      createEvent('referral.scheduled', {
        referralId: referral._id.toString(),
        appointmentId: appointment._id.toString(),
        appointmentDate,
        appointmentTime
      })
    );

    res.status(200).json({
      message: 'Appointment booked successfully for patient',
      referral: {
        id: referral._id,
        appointmentId: appointment._id,
        appointmentDate,
        appointmentTime,
        targetDoctor: `Dr. ${targetDoctor.firstName} ${targetDoctor.lastName}`,
        status: referral.status
      }
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Get Received Referrals (Target Doctor)
 * GET /api/v1/referrals/received
 */
export const getReceivedReferrals = async (req, res, next) => {
  try {
    const { id: targetDoctorId } = req.user;
    const { status, urgency, startDate, endDate, page, limit } = req.query;

    // Build query
    const query = {
      targetDoctorId
    };

    if (status) query.status = status;
    if (urgency) query.urgency = urgency;
    Object.assign(query, buildDateRangeQuery(startDate, endDate));

    // Get total count
    const totalReferrals = await Referral.countDocuments(query);

    // Calculate pagination
    const { skip, limit: itemsPerPage, pagination } = calculatePagination(
      page,
      limit,
      totalReferrals
    );

    // Get referrals
    const referrals = await Referral.find(query)
      .sort({ urgency: -1, referralDate: -1 })
      .skip(skip)
      .limit(itemsPerPage);

    // Format referrals
    const formattedReferrals = await Promise.all(
      referrals.map(async (referral) => {
        const [patient, referringDoctor] = await Promise.all([
          getPatientInfo(referral.patientId),
          getDoctorInfo(referral.referringDoctorId)
        ]);

        return {
          id: referral._id,
          referralDate: referral.referralDate,
          urgency: referral.urgency,
          status: referral.status,
          specialty: referral.specialty,
          patient: {
            id: patient._id,
            name: `${patient.firstName} ${patient.lastName}`,
            age: patient.age || null
          },
          referringDoctor: {
            name: `Dr. ${referringDoctor.firstName} ${referringDoctor.lastName}`,
            specialty: referringDoctor.specialty
          },
          reason: referral.reason,
          diagnosis: referral.diagnosis,
          hasAppointment: referral.isAppointmentBooked
        };
      })
    );

    // Get summary counts
    const summary = {
      pending: await Referral.countDocuments({ targetDoctorId, status: 'pending' }),
      urgent: await Referral.countDocuments({ targetDoctorId, urgency: 'urgent', status: { $in: ['pending', 'scheduled'] } }),
      emergency: await Referral.countDocuments({ targetDoctorId, urgency: 'emergency', status: { $in: ['pending', 'scheduled'] } })
    };

    res.status(200).json({
      referrals: formattedReferrals,
      pagination,
      summary
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Get Sent Referrals (Referring Doctor)
 * GET /api/v1/referrals/sent
 */
export const getSentReferrals = async (req, res, next) => {
  try {
    const { id: referringDoctorId } = req.user;
    const { status, patientId, specialty, page, limit } = req.query;

    // Build query
    const query = {
      referringDoctorId
    };

    if (status) query.status = status;
    if (patientId) query.patientId = patientId;
    if (specialty) query.specialty = new RegExp(specialty, 'i');

    // Get total count
    const totalReferrals = await Referral.countDocuments(query);

    // Calculate pagination
    const { skip, limit: itemsPerPage, pagination } = calculatePagination(
      page,
      limit,
      totalReferrals
    );

    // Get referrals
    const referrals = await Referral.find(query)
      .sort({ referralDate: -1 })
      .skip(skip)
      .limit(itemsPerPage);

    // Format referrals
    const formattedReferrals = await Promise.all(
      referrals.map(async (referral) => {
        const [patient, targetDoctor] = await Promise.all([
          getPatientInfo(referral.patientId),
          getDoctorInfo(referral.targetDoctorId)
        ]);

        return {
          id: referral._id,
          referralDate: referral.referralDate,
          status: referral.status,
          urgency: referral.urgency,
          specialty: referral.specialty,
          patient: {
            id: patient._id,
            name: `${patient.firstName} ${patient.lastName}`
          },
          targetDoctor: {
            id: targetDoctor._id,
            name: `Dr. ${targetDoctor.firstName} ${targetDoctor.lastName}`,
            specialty: targetDoctor.specialty
          },
          reason: referral.reason,
          hasAppointment: referral.isAppointmentBooked,
          responseNotes: referral.responseNotes,
          feedback: referral.feedback
        };
      })
    );

    res.status(200).json({
      referrals: formattedReferrals,
      pagination
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Accept Referral (Target Doctor)
 * PUT /api/v1/referrals/:referralId/accept
 */
export const acceptReferral = async (req, res, next) => {
  try {
    const { id: targetDoctorId } = req.user;
    const { referralId } = req.params;
    const { responseNotes } = req.body;

    const referral = await Referral.findById(referralId);

    if (!referral) {
      return sendError(res, 404, 'REFERRAL_NOT_FOUND',
        'The referral you are looking for does not exist.');
    }

    // Verify target doctor
    if (referral.targetDoctorId.toString() !== targetDoctorId.toString()) {
      return sendError(res, 403, 'FORBIDDEN',
        'You can only accept referrals directed to you.');
    }

    // Check status
    if (!['pending', 'scheduled'].includes(referral.status)) {
      return sendError(res, 400, 'INVALID_STATUS',
        `Cannot accept referral with status: ${referral.status}`);
    }

    // Update referral
    referral.status = 'accepted';
    if (responseNotes) {
      referral.responseNotes = responseNotes;
    }
    referral.addStatusHistory('accepted', targetDoctorId, responseNotes || 'Referral accepted');
    await referral.save();

    // Publish Kafka event
    await kafkaProducer.sendEvent(
      TOPICS.REFERRAL.REFERRAL_ACCEPTED,
      createEvent('referral.accepted', {
        referralId: referral._id.toString(),
        targetDoctorId: targetDoctorId.toString()
      })
    );

    res.status(200).json({
      message: 'Referral accepted successfully'
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Reject Referral (Target Doctor)
 * PUT /api/v1/referrals/:referralId/reject
 */
export const rejectReferral = async (req, res, next) => {
  try {
    const { id: targetDoctorId } = req.user;
    const { referralId } = req.params;
    const { responseNotes, suggestedDoctors } = req.body;

    const referral = await Referral.findById(referralId);

    if (!referral) {
      return sendError(res, 404, 'REFERRAL_NOT_FOUND',
        'The referral you are looking for does not exist.');
    }

    // Verify target doctor
    if (referral.targetDoctorId.toString() !== targetDoctorId.toString()) {
      return sendError(res, 403, 'FORBIDDEN',
        'You can only reject referrals directed to you.');
    }

    // Check status
    if (['completed', 'cancelled', 'rejected'].includes(referral.status)) {
      return sendError(res, 400, 'INVALID_STATUS',
        `Cannot reject referral with status: ${referral.status}`);
    }

    // Cancel appointment if booked
    if (referral.isAppointmentBooked && referral.appointmentId) {
      await cancelAppointment(referral.appointmentId, req.headers.authorization);
      referral.isAppointmentBooked = false;
    }

    // Update referral
    referral.status = 'rejected';
    referral.responseNotes = responseNotes;
    if (suggestedDoctors) {
      referral.suggestedDoctors = suggestedDoctors;
    }
    referral.addStatusHistory('rejected', targetDoctorId, responseNotes);
    await referral.save();

    // Get suggested doctor info
    let suggestedDoctorInfo = [];
    if (suggestedDoctors && suggestedDoctors.length > 0) {
      suggestedDoctorInfo = await Promise.all(
        suggestedDoctors.map(doctorId => getDoctorInfo(doctorId))
      );
      suggestedDoctorInfo = suggestedDoctorInfo
        .filter(doc => doc !== null)
        .map(doc => ({
          id: doc._id,
          name: `Dr. ${doc.firstName} ${doc.lastName}`,
          specialty: doc.specialty
        }));
    }

    // Publish Kafka event
    await kafkaProducer.sendEvent(
      TOPICS.REFERRAL.REFERRAL_REJECTED,
      createEvent('referral.rejected', {
        referralId: referral._id.toString(),
        targetDoctorId: targetDoctorId.toString(),
        hasSuggestions: suggestedDoctors && suggestedDoctors.length > 0
      })
    );

    res.status(200).json({
      message: 'Referral rejected',
      suggestedDoctors: suggestedDoctorInfo
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Complete Referral (Target Doctor)
 * PUT /api/v1/referrals/:referralId/complete
 */
export const completeReferral = async (req, res, next) => {
  try {
    const { id: targetDoctorId } = req.user;
    const { referralId } = req.params;
    const { feedback, consultationCreated } = req.body;

    const referral = await Referral.findById(referralId);

    if (!referral) {
      return sendError(res, 404, 'REFERRAL_NOT_FOUND',
        'The referral you are looking for does not exist.');
    }

    // Verify target doctor
    if (referral.targetDoctorId.toString() !== targetDoctorId.toString()) {
      return sendError(res, 403, 'FORBIDDEN',
        'You can only complete referrals directed to you.');
    }

    // Check status
    if (!['accepted', 'scheduled', 'in_progress'].includes(referral.status)) {
      return sendError(res, 400, 'INVALID_STATUS',
        `Cannot complete referral with status: ${referral.status}`);
    }

    // Update referral
    referral.status = 'completed';
    referral.feedback = feedback;
    referral.addStatusHistory(
      'completed',
      targetDoctorId,
      consultationCreated ? 'Consultation completed and documented' : 'Referral completed'
    );
    await referral.save();

    // Publish Kafka event
    await kafkaProducer.sendEvent(
      TOPICS.REFERRAL.REFERRAL_COMPLETED,
      createEvent('referral.completed', {
        referralId: referral._id.toString(),
        targetDoctorId: targetDoctorId.toString(),
        consultationCreated: consultationCreated || false
      })
    );

    res.status(200).json({
      message: 'Referral completed successfully'
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Cancel Referral
 * PUT /api/v1/referrals/:referralId/cancel
 */
export const cancelReferral = async (req, res, next) => {
  try {
    const { id: userId, role } = req.user;
    const { referralId } = req.params;
    const { cancellationReason } = req.body;

    const referral = await Referral.findById(referralId);

    if (!referral) {
      return sendError(res, 404, 'REFERRAL_NOT_FOUND',
        'The referral you are looking for does not exist.');
    }

    // Verify user can cancel
    if (!referral.canUserCancel(userId, role)) {
      return sendError(res, 403, 'FORBIDDEN',
        'You do not have permission to cancel this referral.');
    }

    // Check status
    if (['completed', 'cancelled'].includes(referral.status)) {
      return sendError(res, 400, 'INVALID_STATUS',
        `Cannot cancel referral with status: ${referral.status}`);
    }

    // Cancel appointment if booked
    if (referral.isAppointmentBooked && referral.appointmentId) {
      await cancelAppointment(referral.appointmentId, req.headers.authorization);
    }

    // Update referral
    referral.status = 'cancelled';
    referral.cancellationReason = cancellationReason;
    referral.addStatusHistory('cancelled', userId, cancellationReason);
    await referral.save();

    // Publish Kafka event
    await kafkaProducer.sendEvent(
      TOPICS.REFERRAL.REFERRAL_CANCELLED,
      createEvent('referral.cancelled', {
        referralId: referral._id.toString(),
        cancelledBy: userId.toString(),
        cancelledByRole: role
      })
    );

    res.status(200).json({
      message: 'Referral cancelled successfully'
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Get Patient's Referrals
 * GET /api/v1/referrals/my-referrals
 */
export const getMyReferrals = async (req, res, next) => {
  try {
    const { id: patientId } = req.user;

    const referrals = await Referral.find({ patientId })
      .sort({ referralDate: -1 });

    // Format referrals (simplified view for patient)
    const formattedReferrals = await Promise.all(
      referrals.map(async (referral) => {
        const [referringDoctor, targetDoctor] = await Promise.all([
          getDoctorInfo(referral.referringDoctorId),
          getDoctorInfo(referral.targetDoctorId)
        ]);

        let appointment = null;
        if (referral.appointmentId) {
          appointment = await getAppointmentDetails(referral.appointmentId);
        }

        return {
          id: referral._id,
          date: referral.referralDate,
          referredBy: `Dr. ${referringDoctor.firstName} ${referringDoctor.lastName}`,
          referredTo: `Dr. ${targetDoctor.firstName} ${targetDoctor.lastName}`,
          specialty: referral.specialty,
          reason: referral.reason,
          status: referral.status,
          urgency: referral.urgency,
          appointment: appointment ? {
            date: appointment.appointmentDate,
            time: appointment.appointmentTime,
            status: appointment.status
          } : null
        };
      })
    );

    res.status(200).json({
      referrals: formattedReferrals
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Get Referral Statistics
 * GET /api/v1/referrals/statistics
 */
export const getReferralStatistics = async (req, res, next) => {
  try {
    const { id: doctorId, role } = req.user;

    if (role !== 'doctor') {
      return sendError(res, 403, 'FORBIDDEN',
        'Only doctors can view referral statistics.');
    }

    // Check if doctor is referring or receiving referrals
    const isReferringDoctor = await Referral.exists({ referringDoctorId: doctorId });
    const isTargetDoctor = await Referral.exists({ targetDoctorId: doctorId });

    let statistics = {};

    if (isReferringDoctor) {
      // Statistics for referring doctor
      const [
        totalReferralsSent,
        pending,
        scheduled,
        completed,
        rejected,
        specialtyAgg
      ] = await Promise.all([
        Referral.countDocuments({ referringDoctorId: doctorId }),
        Referral.countDocuments({ referringDoctorId: doctorId, status: 'pending' }),
        Referral.countDocuments({ referringDoctorId: doctorId, status: 'scheduled' }),
        Referral.countDocuments({ referringDoctorId: doctorId, status: 'completed' }),
        Referral.countDocuments({ referringDoctorId: doctorId, status: 'rejected' }),
        Referral.aggregate([
          { $match: { referringDoctorId: doctorId } },
          { $group: { _id: '$specialty', count: { $sum: 1 } } },
          { $sort: { count: -1 } },
          { $limit: 5 }
        ])
      ]);

      statistics.sent = {
        totalReferralsSent,
        pending,
        scheduled,
        completed,
        rejected,
        topSpecialties: specialtyAgg.map(item => ({
          specialty: item._id,
          count: item.count
        }))
      };
    }

    if (isTargetDoctor) {
      // Statistics for target doctor (receiving referrals)
      const [
        totalReferralsReceived,
        pending,
        completed,
        sourceAgg
      ] = await Promise.all([
        Referral.countDocuments({ targetDoctorId: doctorId }),
        Referral.countDocuments({ targetDoctorId: doctorId, status: 'pending' }),
        Referral.countDocuments({ targetDoctorId: doctorId, status: 'completed' }),
        Referral.aggregate([
          { $match: { targetDoctorId: doctorId } },
          { $group: { _id: '$referringDoctorId', count: { $sum: 1 } } },
          { $sort: { count: -1 } },
          { $limit: 5 }
        ])
      ]);

      // Get referring doctor names
      const topReferringSources = await Promise.all(
        sourceAgg.map(async (item) => {
          const doctor = await getDoctorInfo(item._id);
          return {
            doctor: doctor ? `Dr. ${doctor.firstName} ${doctor.lastName}` : 'Unknown',
            count: item.count
          };
        })
      );

      statistics.received = {
        totalReferralsReceived,
        pending,
        completed,
        topReferringSources
      };
    }

    res.status(200).json({
      statistics
    });
  } catch (error) {
    next(error);
  }
};
