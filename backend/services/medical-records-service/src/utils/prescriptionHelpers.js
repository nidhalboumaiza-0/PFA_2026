import Consultation from '../models/Consultation.js';
import { getDoctorBasicInfo } from './consultationHelpers.js';

/**
 * Fetch consultation details
 */
export const fetchConsultationDetails = async (consultationId) => {
  const consultation = await Consultation.findById(consultationId);
  if (!consultation) {
    throw new Error('Consultation not found');
  }
  return consultation;
};

/**
 * Check if doctor owns the consultation
 */
export const verifyConsultationOwnership = (consultation, doctorId) => {
  if (consultation.doctorId.toString() !== doctorId.toString()) {
    throw new Error('You can only create prescriptions for your own consultations');
  }
  return true;
};

/**
 * Format remaining time in human-readable format
 */
export const formatRemainingTime = (minutes) => {
  if (minutes <= 0) {
    return 'Expired';
  }
  
  if (minutes < 60) {
    return `${minutes} minute${minutes !== 1 ? 's' : ''}`;
  }
  
  const hours = Math.floor(minutes / 60);
  const mins = minutes % 60;
  
  if (mins === 0) {
    return `${hours} hour${hours !== 1 ? 's' : ''}`;
  }
  
  return `${hours} hour${hours !== 1 ? 's' : ''} ${mins} minute${mins !== 1 ? 's' : ''}`;
};

/**
 * Build date range query for prescriptions
 */
export const buildPrescriptionDateQuery = (startDate, endDate) => {
  const query = {};
  
  if (startDate || endDate) {
    query.prescriptionDate = {};
    if (startDate) {
      query.prescriptionDate.$gte = new Date(startDate);
    }
    if (endDate) {
      query.prescriptionDate.$lte = new Date(endDate);
    }
  }
  
  return query;
};

/**
 * Format prescription for list view
 */
export const formatPrescriptionForList = async (prescription) => {
  const doctor = await getDoctorBasicInfo(prescription.doctorId);
  
  return {
    id: prescription._id,
    date: prescription.prescriptionDate,
    doctor: doctor.name,
    medicationCount: prescription.medicationCount,
    medicationSummary: prescription.medicationSummary,
    isLocked: prescription.isLocked,
    status: prescription.status
  };
};

/**
 * Format modification history for response
 */
export const formatModificationHistory = async (history) => {
  return Promise.all(
    history.map(async (entry) => {
      let modifiedByInfo = null;
      
      if (entry.modifiedBy) {
        const doctor = await getDoctorBasicInfo(entry.modifiedBy);
        modifiedByInfo = {
          id: entry.modifiedBy,
          name: doctor.name
        };
      }
      
      return {
        modifiedAt: entry.modifiedAt,
        modifiedBy: modifiedByInfo,
        changeType: entry.changeType,
        changes: formatChanges(entry.changeType, entry.changes, entry.previousData)
      };
    })
  );
};

/**
 * Format changes for human-readable output
 */
const formatChanges = (changeType, changes, previousData) => {
  switch (changeType) {
    case 'created':
      return 'Initial prescription created';
    
    case 'auto_locked':
      return 'Prescription automatically locked after 1 hour';
    
    case 'manual_locked':
      return 'Prescription manually locked by doctor';
    
    case 'updated':
      const changeDescriptions = {};
      
      if (changes.medications && previousData?.medications) {
        // Compare medications
        const oldMeds = previousData.medications.map(m => m.medicationName).join(', ');
        const newMeds = changes.medications ? 'Updated' : oldMeds;
        changeDescriptions.medications = `Medications modified`;
      }
      
      if (changes.generalInstructions !== undefined) {
        changeDescriptions.generalInstructions = 'General instructions updated';
      }
      
      if (changes.specialWarnings !== undefined) {
        changeDescriptions.specialWarnings = 'Special warnings updated';
      }
      
      if (changes.status !== undefined) {
        changeDescriptions.status = `Status changed to ${changes.status}`;
      }
      
      return changeDescriptions;
    
    default:
      return changes;
  }
};

/**
 * Create snapshot of prescription data for history
 */
export const createPrescriptionSnapshot = (prescription) => {
  return {
    medications: prescription.medications.map(m => ({
      medicationName: m.medicationName,
      dosage: m.dosage,
      form: m.form,
      frequency: m.frequency,
      duration: m.duration,
      instructions: m.instructions,
      quantity: m.quantity,
      notes: m.notes
    })),
    generalInstructions: prescription.generalInstructions,
    specialWarnings: prescription.specialWarnings,
    status: prescription.status
  };
};

/**
 * Detect changes between old and new prescription data
 */
export const detectChanges = (oldData, newData) => {
  const changes = {};
  
  if (JSON.stringify(oldData.medications) !== JSON.stringify(newData.medications)) {
    changes.medications = true;
  }
  
  if (oldData.generalInstructions !== newData.generalInstructions) {
    changes.generalInstructions = true;
  }
  
  if (oldData.specialWarnings !== newData.specialWarnings) {
    changes.specialWarnings = true;
  }
  
  if (oldData.status !== newData.status) {
    changes.status = newData.status;
  }
  
  return changes;
};

/**
 * Get active prescriptions within timeframe (default 3 months)
 */
export const getActivePrescriptionsQuery = (patientId, months = 3) => {
  const threeMonthsAgo = new Date();
  threeMonthsAgo.setMonth(threeMonthsAgo.getMonth() - months);
  
  return {
    patientId,
    status: 'active',
    prescriptionDate: { $gte: threeMonthsAgo }
  };
};

/**
 * Update consultation with prescription reference
 */
export const linkPrescriptionToConsultation = async (consultationId, prescriptionId) => {
  const consultation = await Consultation.findById(consultationId);
  if (consultation) {
    consultation.prescriptionId = prescriptionId;
    await consultation.save();
  }
};
