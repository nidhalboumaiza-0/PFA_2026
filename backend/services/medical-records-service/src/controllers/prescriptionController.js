import Prescription from '../models/Prescription.js';
import { kafkaProducer, TOPICS, createEvent } from '../../../../shared/index.js';
import {
  fetchConsultationDetails,
  verifyConsultationOwnership,
  formatRemainingTime,
  buildPrescriptionDateQuery,
  formatPrescriptionForList,
  formatModificationHistory,
  createPrescriptionSnapshot,
  detectChanges,
  getActivePrescriptionsQuery,
  linkPrescriptionToConsultation
} from '../utils/prescriptionHelpers.js';
import { getDoctorBasicInfo, getPatientBasicInfo, calculatePagination } from '../utils/consultationHelpers.js';

/**
 * Create Prescription
 * POST /api/v1/medical/prescriptions
 */
export const createPrescription = async (req, res, next) => {
  try {
    const { id: doctorId } = req.user;
    const {
      consultationId,
      medications,
      generalInstructions,
      specialWarnings,
      pharmacyName,
      pharmacyAddress,
      status
    } = req.body;

    // Verify consultation exists
    const consultation = await fetchConsultationDetails(consultationId);

    // Verify doctor owns the consultation
    verifyConsultationOwnership(consultation, doctorId);

    // Check if prescription already exists for this consultation
    const existingPrescription = await Prescription.findOne({ consultationId });
    if (existingPrescription) {
      return res.status(409).json({
        message: 'Prescription already exists for this consultation'
      });
    }

    // Create prescription
    const prescription = await Prescription.create({
      consultationId,
      patientId: consultation.patientId,
      doctorId,
      medications,
      generalInstructions,
      specialWarnings,
      pharmacyName,
      pharmacyAddress,
      status: status || 'active',
      createdBy: doctorId
    });

    // Link prescription to consultation
    await linkPrescriptionToConsultation(consultationId, prescription._id);

    // Publish Kafka event
    await kafkaProducer.sendEvent(
      TOPICS.MEDICAL.PRESCRIPTION_CREATED,
      createEvent('prescription.created', {
        prescriptionId: prescription._id.toString(),
        consultationId: consultationId.toString(),
        patientId: consultation.patientId.toString(),
        doctorId: doctorId.toString(),
        medicationCount: prescription.medicationCount,
        canEditUntil: prescription.canEditUntil
      })
    );

    const remainingMinutes = prescription.getRemainingEditTime();

    res.status(201).json({
      message: 'Prescription created successfully. You can edit it for 1 hour.',
      prescription: {
        id: prescription._id,
        prescriptionDate: prescription.prescriptionDate,
        canEditUntil: prescription.canEditUntil,
        remainingEditTime: formatRemainingTime(remainingMinutes),
        medications: prescription.medications,
        generalInstructions: prescription.generalInstructions,
        specialWarnings: prescription.specialWarnings,
        isEditable: prescription.isEditable(),
        isLocked: prescription.isLocked,
        status: prescription.status
      }
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Get Prescription by ID
 * GET /api/v1/medical/prescriptions/:prescriptionId
 */
export const getPrescriptionById = async (req, res, next) => {
  try {
    const { id: userId, role } = req.user;
    const { prescriptionId } = req.params;

    const prescription = await Prescription.findById(prescriptionId);

    if (!prescription) {
      return res.status(404).json({
        message: 'Prescription not found'
      });
    }

    // Auto-lock if time expired
    await prescription.checkAndLock();

    // Verify access
    if (role === 'patient') {
      if (prescription.patientId.toString() !== userId.toString()) {
        return res.status(403).json({
          message: 'You can only view your own prescriptions'
        });
      }
    } else if (role === 'doctor') {
      // Doctor must have treated this patient
      const Consultation = (await import('../models/Consultation.js')).default;
      const hasAccess = await Consultation.findOne({
        patientId: prescription.patientId,
        doctorId: userId
      });
      
      if (!hasAccess) {
        return res.status(403).json({
          message: 'You can only view prescriptions for patients you have treated'
        });
      }
    }

    // Get doctor and patient info
    const doctor = await getDoctorBasicInfo(prescription.doctorId);
    const patient = await getPatientBasicInfo(prescription.patientId);

    // Publish audit event
    await kafkaProducer.sendEvent(
      TOPICS.MEDICAL.PRESCRIPTION_ACCESSED,
      createEvent('prescription.accessed', {
        prescriptionId: prescription._id.toString(),
        accessedBy: userId.toString()
      })
    );

    const remainingMinutes = prescription.getRemainingEditTime();

    res.status(200).json({
      prescription: {
        id: prescription._id,
        prescriptionDate: prescription.prescriptionDate,
        doctor,
        patient,
        medications: prescription.medications,
        generalInstructions: prescription.generalInstructions,
        specialWarnings: prescription.specialWarnings,
        pharmacyName: prescription.pharmacyName,
        pharmacyAddress: prescription.pharmacyAddress,
        isLocked: prescription.isLocked,
        canEditUntil: prescription.canEditUntil,
        remainingEditTime: formatRemainingTime(remainingMinutes),
        isEditable: prescription.isEditable(),
        status: prescription.status,
        createdAt: prescription.createdAt,
        updatedAt: prescription.updatedAt
      }
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Update Prescription
 * PUT /api/v1/medical/prescriptions/:prescriptionId
 */
export const updatePrescription = async (req, res, next) => {
  try {
    const { id: doctorId } = req.user;
    const { prescriptionId } = req.params;
    const updates = req.body;

    const prescription = await Prescription.findById(prescriptionId);

    if (!prescription) {
      return res.status(404).json({
        message: 'Prescription not found'
      });
    }

    // Verify doctor owns this prescription
    if (prescription.doctorId.toString() !== doctorId.toString()) {
      return res.status(403).json({
        message: 'You can only update your own prescriptions'
      });
    }

    // Auto-lock if time expired
    const wasLocked = await prescription.checkAndLock();

    // Check if editable
    if (!prescription.isEditable()) {
      return res.status(400).json({
        message: 'Prescription is locked and can no longer be edited. The 1-hour editing window has expired.',
        lockedAt: prescription.lockedAt
      });
    }

    // Create snapshot of current data
    const snapshot = createPrescriptionSnapshot(prescription);

    // Update fields
    if (updates.medications) {
      prescription.medications = updates.medications;
    }

    if (updates.generalInstructions !== undefined) {
      prescription.generalInstructions = updates.generalInstructions;
    }

    if (updates.specialWarnings !== undefined) {
      prescription.specialWarnings = updates.specialWarnings;
    }

    if (updates.pharmacyName !== undefined) {
      prescription.pharmacyName = updates.pharmacyName;
    }

    if (updates.pharmacyAddress !== undefined) {
      prescription.pharmacyAddress = updates.pharmacyAddress;
    }

    if (updates.status) {
      prescription.status = updates.status;
    }

    // Detect what changed
    const currentData = createPrescriptionSnapshot(prescription);
    const changes = detectChanges(snapshot, currentData);

    // Add to modification history
    prescription.modificationHistory.push({
      modifiedAt: new Date(),
      modifiedBy: doctorId,
      changeType: 'updated',
      changes,
      previousData: snapshot
    });

    await prescription.save();

    // Publish Kafka event
    await kafkaProducer.sendEvent(
      TOPICS.MEDICAL.PRESCRIPTION_UPDATED,
      createEvent('prescription.updated', {
        prescriptionId: prescription._id.toString(),
        updatedBy: doctorId.toString(),
        modificationType: Object.keys(changes).join(', ')
      })
    );

    const remainingMinutes = prescription.getRemainingEditTime();

    res.status(200).json({
      message: 'Prescription updated successfully',
      prescription: {
        id: prescription._id,
        medications: prescription.medications,
        generalInstructions: prescription.generalInstructions,
        specialWarnings: prescription.specialWarnings,
        remainingEditTime: formatRemainingTime(remainingMinutes),
        isEditable: prescription.isEditable(),
        isLocked: prescription.isLocked,
        updatedAt: prescription.updatedAt
      }
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Manual Lock Prescription
 * POST /api/v1/medical/prescriptions/:prescriptionId/lock
 */
export const lockPrescription = async (req, res, next) => {
  try {
    const { id: doctorId } = req.user;
    const { prescriptionId } = req.params;

    const prescription = await Prescription.findById(prescriptionId);

    if (!prescription) {
      return res.status(404).json({
        message: 'Prescription not found'
      });
    }

    // Verify doctor owns this prescription
    if (prescription.doctorId.toString() !== doctorId.toString()) {
      return res.status(403).json({
        message: 'You can only lock your own prescriptions'
      });
    }

    if (prescription.isLocked) {
      return res.status(400).json({
        message: 'Prescription is already locked'
      });
    }

    // Manually lock
    await prescription.manualLock(doctorId);

    // Publish Kafka event
    await kafkaProducer.sendEvent(
      TOPICS.MEDICAL.PRESCRIPTION_LOCKED,
      createEvent('prescription.locked', {
        prescriptionId: prescription._id.toString(),
        lockType: 'manual',
        lockedBy: doctorId.toString()
      })
    );

    res.status(200).json({
      message: 'Prescription locked successfully',
      prescription: {
        id: prescription._id,
        isLocked: prescription.isLocked,
        lockedAt: prescription.lockedAt
      }
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Get Prescription Modification History
 * GET /api/v1/medical/prescriptions/:prescriptionId/history
 */
export const getPrescriptionHistory = async (req, res, next) => {
  try {
    const { id: doctorId } = req.user;
    const { prescriptionId } = req.params;

    const prescription = await Prescription.findById(prescriptionId);

    if (!prescription) {
      return res.status(404).json({
        message: 'Prescription not found'
      });
    }

    // Verify doctor has access (treated this patient)
    const Consultation = (await import('../models/Consultation.js')).default;
    const hasAccess = await Consultation.findOne({
      patientId: prescription.patientId,
      doctorId
    });

    if (!hasAccess) {
      return res.status(403).json({
        message: 'You can only view history for patients you have treated'
      });
    }

    // Format modification history
    const history = await formatModificationHistory(prescription.modificationHistory);

    res.status(200).json({
      prescriptionId: prescription._id,
      history
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Get Patient's Prescriptions
 * GET /api/v1/medical/patients/:patientId/prescriptions
 */
export const getPatientPrescriptions = async (req, res, next) => {
  try {
    const { id: doctorId } = req.user;
    const { patientId } = req.params;
    const { startDate, endDate, status, page, limit } = req.query;

    // Build query
    const query = { patientId };

    // Add date range
    Object.assign(query, buildPrescriptionDateQuery(startDate, endDate));

    // Add status filter
    if (status !== 'all') {
      query.status = status;
    }

    // Get total count
    const totalPrescriptions = await Prescription.countDocuments(query);

    // Calculate pagination
    const { skip, pagination } = calculatePagination(page, limit, totalPrescriptions);

    // Get prescriptions
    const prescriptions = await Prescription.find(query)
      .sort({ prescriptionDate: -1 })
      .skip(skip)
      .limit(limit);

    // Format for list view
    const formattedPrescriptions = await Promise.all(
      prescriptions.map(p => formatPrescriptionForList(p))
    );

    res.status(200).json({
      prescriptions: formattedPrescriptions,
      pagination
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Get Active Prescriptions for Patient
 * GET /api/v1/medical/patients/:patientId/active-prescriptions
 */
export const getActivePrescriptions = async (req, res, next) => {
  try {
    const { id: doctorId } = req.user;
    const { patientId } = req.params;

    // Get active prescriptions from last 3 months
    const query = getActivePrescriptionsQuery(patientId, 3);

    const prescriptions = await Prescription.find(query)
      .sort({ prescriptionDate: -1 });

    // Format for response
    const activePrescriptions = await Promise.all(
      prescriptions.map(async (p) => {
        const doctor = await getDoctorBasicInfo(p.doctorId);
        return {
          id: p._id,
          date: p.prescriptionDate,
          doctor: doctor.name,
          medications: p.medications.map(m => ({
            name: m.medicationName,
            dosage: m.dosage,
            frequency: m.frequency,
            duration: m.duration
          }))
        };
      })
    );

    res.status(200).json({
      patientId,
      activePrescriptions,
      count: activePrescriptions.length
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Patient: View My Prescriptions
 * GET /api/v1/medical/patients/my-prescriptions
 */
export const getMyPrescriptions = async (req, res, next) => {
  try {
    const { id: patientId } = req.user;
    const { status, page, limit } = req.query;

    // Build query
    const query = { patientId };

    if (status !== 'all') {
      query.status = status;
    }

    // Get total count
    const totalPrescriptions = await Prescription.countDocuments(query);

    // Calculate pagination
    const { skip, pagination } = calculatePagination(
      page || 1,
      limit || 20,
      totalPrescriptions
    );

    // Get prescriptions
    const prescriptions = await Prescription.find(query)
      .sort({ prescriptionDate: -1 })
      .skip(skip)
      .limit(limit || 20);

    // Format for patient view
    const formattedPrescriptions = await Promise.all(
      prescriptions.map(async (p) => {
        const doctor = await getDoctorBasicInfo(p.doctorId);
        return {
          id: p._id,
          date: p.prescriptionDate,
          doctor: {
            name: doctor.name,
            specialty: doctor.specialty
          },
          medications: p.medications,
          generalInstructions: p.generalInstructions,
          specialWarnings: p.specialWarnings,
          pharmacyName: p.pharmacyName,
          status: p.status
        };
      })
    );

    res.status(200).json({
      prescriptions: formattedPrescriptions,
      pagination
    });
  } catch (error) {
    next(error);
  }
};
