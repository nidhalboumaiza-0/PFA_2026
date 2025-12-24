import axios from 'axios';
import { cacheGet, cacheSet, getUserServiceUrl, getRdvServiceUrl } from '../../../../shared/index.js';

// Cache TTLs
const PROFILE_CACHE_TTL = 600; // 10 minutes

/**
 * Fetch patient profile from User Service (cached)
 */
export const fetchPatientProfile = async (patientId) => {
  const cacheKey = `patient_profile:${patientId}`;
  
  // Try cache first
  const cached = await cacheGet(cacheKey);
  if (cached) {
    console.log(`📦 Cache HIT: Patient profile ${patientId}`);
    return cached;
  }

  try {
    const userServiceUrl = await getUserServiceUrl();
    const response = await axios.get(`${userServiceUrl}/api/v1/users/patients/${patientId}`);
    const patient = response.data.patient;
    
    // Cache for 10 minutes
    await cacheSet(cacheKey, patient, PROFILE_CACHE_TTL);
    console.log(`💾 Cache SET: Patient profile ${patientId}`);
    
    return patient;
  } catch (error) {
    if (error.response?.status === 404) {
      throw new Error('Patient not found');
    }
    throw new Error('Failed to fetch patient profile');
  }
};

/**
 * Fetch doctor profile from User Service (cached)
 */
export const fetchDoctorProfile = async (doctorId) => {
  const cacheKey = `doctor_profile:${doctorId}`;
  
  // Try cache first
  const cached = await cacheGet(cacheKey);
  if (cached) {
    console.log(`📦 Cache HIT: Doctor profile ${doctorId}`);
    return cached;
  }

  try {
    const userServiceUrl = await getUserServiceUrl();
    const response = await axios.get(`${userServiceUrl}/api/v1/users/doctors/${doctorId}`);
    const doctor = response.data.doctor;
    
    // Cache for 10 minutes
    await cacheSet(cacheKey, doctor, PROFILE_CACHE_TTL);
    console.log(`💾 Cache SET: Doctor profile ${doctorId}`);
    
    return doctor;
  } catch (error) {
    if (error.response?.status === 404) {
      throw new Error('Doctor not found');
    }
    throw new Error('Failed to fetch doctor profile');
  }
};

/**
 * Fetch appointment details from RDV Service
 */
export const fetchAppointmentDetails = async (appointmentId, authToken) => {
  try {
    const rdvServiceUrl = await getRdvServiceUrl();
    const response = await axios.get(
      `${rdvServiceUrl}/api/v1/appointments/${appointmentId}`,
      {
        headers: {
          Authorization: `Bearer ${authToken}`
        }
      }
    );
    return response.data.appointment;
  } catch (error) {
    if (error.response?.status === 404) {
      throw new Error('Appointment not found');
    }
    if (error.response?.status === 403) {
      throw new Error('You do not have access to this appointment');
    }
    throw new Error('Failed to fetch appointment details');
  }
};

/**
 * Check if doctor has treated patient before
 */
export const hasDoctorTreatedPatient = async (Consultation, doctorId, patientId) => {
  const consultation = await Consultation.findOne({
    doctorId,
    patientId
  });
  return !!consultation;
};

/**
 * Get patient basic info for timeline
 */
export const getPatientBasicInfo = async (patientId) => {
  try {
    const patient = await fetchPatientProfile(patientId);
    return {
      id: patient._id,
      name: patient.fullName || `${patient.firstName} ${patient.lastName}`,
      dateOfBirth: patient.dateOfBirth,
      age: patient.age
    };
  } catch (error) {
    return {
      id: patientId,
      name: 'Unknown Patient'
    };
  }
};

/**
 * Get doctor basic info for timeline
 */
export const getDoctorBasicInfo = async (doctorId) => {
  try {
    const doctor = await fetchDoctorProfile(doctorId);
    return {
      id: doctor._id,
      name: doctor.fullName || `${doctor.firstName} ${doctor.lastName}`,
      specialty: doctor.specialty
    };
  } catch (error) {
    return {
      id: doctorId,
      name: 'Unknown Doctor'
    };
  }
};

/**
 * Build date range query
 */
export const buildDateRangeQuery = (startDate, endDate) => {
  const query = {};
  
  if (startDate || endDate) {
    query.consultationDate = {};
    if (startDate) {
      query.consultationDate.$gte = new Date(startDate);
    }
    if (endDate) {
      query.consultationDate.$lte = new Date(endDate);
    }
  }
  
  return query;
};

/**
 * Calculate pagination
 */
export const calculatePagination = (page, limit, totalCount) => {
  const totalPages = Math.ceil(totalCount / limit);
  const skip = (page - 1) * limit;
  
  return {
    skip,
    pagination: {
      currentPage: page,
      totalPages,
      totalItems: totalCount
    }
  };
};

/**
 * Format consultation for timeline view
 */
export const formatConsultationForTimeline = async (consultation) => {
  const doctor = await getDoctorBasicInfo(consultation.doctorId);
  
  return {
    consultationId: consultation._id,
    date: consultation.consultationDate,
    doctor,
    chiefComplaint: consultation.chiefComplaint,
    diagnosis: consultation.medicalNote?.diagnosis || 'Not specified',
    hasPrescription: !!consultation.prescriptionId,
    documentCount: consultation.documentIds?.length || 0,
    status: consultation.status
  };
};

/**
 * Format consultation for patient view (simplified)
 */
export const formatConsultationForPatient = async (consultation) => {
  const doctor = await getDoctorBasicInfo(consultation.doctorId);
  
  return {
    id: consultation._id,
    date: consultation.consultationDate,
    doctor: {
      name: doctor.name,
      specialty: doctor.specialty
    },
    reason: consultation.chiefComplaint,
    diagnosis: consultation.medicalNote?.diagnosis || 'Not specified',
    hasPrescription: !!consultation.prescriptionId,
    hasDocuments: consultation.documentIds?.length > 0
  };
};

/**
 * Log audit event (to be sent via Kafka)
 */
export const createAuditLog = (action, performedBy, resourceType, resourceId, additionalData = {}) => {
  return {
    action,
    performedBy: performedBy.toString(),
    resourceType,
    resourceId: resourceId.toString(),
    timestamp: new Date(),
    ...additionalData
  };
};
