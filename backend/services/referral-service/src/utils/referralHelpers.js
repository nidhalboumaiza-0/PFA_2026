import axios from 'axios';
import { cacheGet, cacheSet, getUserServiceUrl, getRdvServiceUrl, getMedicalRecordsServiceUrl } from '../../../../shared/index.js';

// Cache TTL
const PROFILE_CACHE_TTL = 600; // 10 minutes

/**
 * Get User Info (Patient or Doctor)
 */
export const getUserInfo = async (userId, token) => {
  try {
    const userServiceUrl = await getUserServiceUrl();
    const response = await axios.get(`${userServiceUrl}/profile/${userId}`, {
      headers: { Authorization: `Bearer ${token}` }
    });
    return response.data.profile || null;
  } catch (error) {
    console.error('Error fetching user info:', error.message);
    return null;
  }
};

/**
 * Get Doctor Info by ID (cached)
 */
export const getDoctorInfo = async (doctorId) => {
  const cacheKey = `referral_doctor:${doctorId}`;
  
  // Try cache first
  const cached = await cacheGet(cacheKey);
  if (cached) {
    console.log(`📦 Cache HIT: Referral doctor ${doctorId}`);
    return cached;
  }

  try {
    const userServiceUrl = await getUserServiceUrl();
    const response = await axios.get(`${userServiceUrl}/doctors/${doctorId}`);
    const doctor = response.data.doctor || null;
    
    if (doctor) {
      await cacheSet(cacheKey, doctor, PROFILE_CACHE_TTL);
      console.log(`💾 Cache SET: Referral doctor ${doctorId}`);
    }
    
    return doctor;
  } catch (error) {
    console.error('Error fetching doctor info:', error.message);
    return null;
  }
};

/**
 * Get Patient Info by ID (cached)
 */
export const getPatientInfo = async (patientId) => {
  const cacheKey = `referral_patient:${patientId}`;
  
  // Try cache first
  const cached = await cacheGet(cacheKey);
  if (cached) {
    console.log(`📦 Cache HIT: Referral patient ${patientId}`);
    return cached;
  }

  try {
    const userServiceUrl = await getUserServiceUrl();
    const response = await axios.get(`${userServiceUrl}/patients/${patientId}`);
    const patient = response.data.patient || null;
    
    if (patient) {
      await cacheSet(cacheKey, patient, PROFILE_CACHE_TTL);
      console.log(`💾 Cache SET: Referral patient ${patientId}`);
    }
    
    return patient;
  } catch (error) {
    console.error('Error fetching patient info:', error.message);
    return null;
  }
};

/**
 * Check if Doctor has Treated Patient
 */
export const hasDoctorTreatedPatient = async (doctorId, patientId) => {
  try {
    const medicalRecordsUrl = await getMedicalRecordsServiceUrl();
    const response = await axios.get(
      `${medicalRecordsUrl}/consultations/check-history`,
      {
        params: { doctorId, patientId }
      }
    );
    return response.data.hasTreated || false;
  } catch (error) {
    // If endpoint doesn't exist, check via RDV service
    try {
      const rdvServiceUrl = await getRdvServiceUrl();
      const rdvResponse = await axios.get(
        `${rdvServiceUrl}/appointments/check-history`,
        {
          params: { doctorId, patientId }
        }
      );
      return rdvResponse.data.hasHistory || false;
    } catch (rdvError) {
      console.error('Error checking treatment history:', error.message);
      return false;
    }
  }
};

/**
 * Verify Doctor Specialty Matches
 */
export const verifyDoctorSpecialty = async (doctorId, expectedSpecialty) => {
  const doctor = await getDoctorInfo(doctorId);
  if (!doctor) return false;
  
  return doctor.specialty?.toLowerCase() === expectedSpecialty.toLowerCase();
};

/**
 * Search Specialists
 */
export const searchSpecialists = async (criteria) => {
  try {
    const { specialty, city, latitude, longitude, radius, availableAfter } = criteria;
    
    const params = {
      role: 'doctor',
      specialty,
      isVerified: true,
      isActive: true
    };
    
    if (city) params.city = city;
    if (latitude && longitude) {
      params.latitude = latitude;
      params.longitude = longitude;
      params.radius = radius || 10;
    }
    
    const userServiceUrl = await getUserServiceUrl();
    const response = await axios.get(`${userServiceUrl}/search`, { params });
    return response.data.doctors || [];
  } catch (error) {
    console.error('Error searching specialists:', error.message);
    return [];
  }
};

/**
 * Check Doctor Availability
 */
export const checkDoctorAvailability = async (doctorId, date, time) => {
  try {
    const response = await axios.get(
      `${RDV_SERVICE_URL}/availability/check`,
      {
        params: { doctorId, date, time }
      }
    );
    return response.data.available || false;
  } catch (error) {
    console.error('Error checking availability:', error.message);
    return false;
  }
};

/**
 * Create Appointment for Referral
 */
export const createReferralAppointment = async (referralData, token) => {
  try {
    const {
      patientId,
      targetDoctorId,
      referringDoctorId,
      appointmentDate,
      appointmentTime,
      referralId,
      notes
    } = referralData;
    
    const response = await axios.post(
      `${RDV_SERVICE_URL}/appointments/referral`,
      {
        patientId,
        doctorId: targetDoctorId,
        referredBy: referringDoctorId,
        referralId,
        appointmentDate,
        appointmentTime,
        status: 'confirmed',
        notes
      },
      {
        headers: { Authorization: `Bearer ${token}` }
      }
    );
    
    return response.data.appointment || null;
  } catch (error) {
    console.error('Error creating referral appointment:', error.message);
    throw error;
  }
};

/**
 * Cancel Appointment
 */
export const cancelAppointment = async (appointmentId, token) => {
  try {
    await axios.put(
      `${RDV_SERVICE_URL}/appointments/${appointmentId}/cancel`,
      { cancellationReason: 'Referral cancelled' },
      {
        headers: { Authorization: `Bearer ${token}` }
      }
    );
    return true;
  } catch (error) {
    console.error('Error cancelling appointment:', error.message);
    return false;
  }
};

/**
 * Get Appointment Details
 */
export const getAppointmentDetails = async (appointmentId) => {
  try {
    const response = await axios.get(`${RDV_SERVICE_URL}/appointments/${appointmentId}`);
    return response.data.appointment || null;
  } catch (error) {
    console.error('Error fetching appointment:', error.message);
    return null;
  }
};

/**
 * Get Document Details
 */
export const getDocumentDetails = async (documentId, token) => {
  try {
    const response = await axios.get(
      `${MEDICAL_RECORDS_SERVICE_URL}/documents/${documentId}`,
      {
        headers: { Authorization: `Bearer ${token}` }
      }
    );
    return response.data.document || null;
  } catch (error) {
    console.error('Error fetching document:', error.message);
    return null;
  }
};

/**
 * Verify Documents Belong to Patient
 */
export const verifyDocumentsOwnership = async (documentIds, patientId, token) => {
  try {
    for (const docId of documentIds) {
      const doc = await getDocumentDetails(docId, token);
      if (!doc || doc.patientId !== patientId.toString()) {
        return false;
      }
    }
    return true;
  } catch (error) {
    console.error('Error verifying documents:', error.message);
    return false;
  }
};

/**
 * Format Referral for Response
 */
export const formatReferralForResponse = async (referral, includeFullDetails = false) => {
  const formatted = {
    id: referral._id,
    referralDate: referral.referralDate,
    status: referral.status,
    urgency: referral.urgency,
    specialty: referral.specialty,
    reason: referral.reason
  };
  
  if (includeFullDetails) {
    formatted.diagnosis = referral.diagnosis;
    formatted.symptoms = referral.symptoms;
    formatted.relevantHistory = referral.relevantHistory;
    formatted.currentMedications = referral.currentMedications;
    formatted.specificConcerns = referral.specificConcerns;
    formatted.referralNotes = referral.referralNotes;
    formatted.responseNotes = referral.responseNotes;
    formatted.feedback = referral.feedback;
    formatted.statusHistory = referral.statusHistory;
    formatted.expiryDate = referral.expiryDate;
    formatted.isAppointmentBooked = referral.isAppointmentBooked;
  }
  
  return formatted;
};

/**
 * Calculate Pagination
 */
export const calculatePagination = (page, limit, totalItems) => {
  const currentPage = parseInt(page) || 1;
  const itemsPerPage = parseInt(limit) || 20;
  const totalPages = Math.ceil(totalItems / itemsPerPage);
  const skip = (currentPage - 1) * itemsPerPage;
  
  return {
    skip,
    limit: itemsPerPage,
    pagination: {
      currentPage,
      totalPages,
      totalItems,
      itemsPerPage,
      hasNextPage: currentPage < totalPages,
      hasPrevPage: currentPage > 1
    }
  };
};

/**
 * Build Date Range Query
 */
export const buildDateRangeQuery = (startDate, endDate) => {
  const query = {};
  
  if (startDate || endDate) {
    query.referralDate = {};
    if (startDate) {
      query.referralDate.$gte = new Date(startDate);
    }
    if (endDate) {
      query.referralDate.$lte = new Date(endDate);
    }
  }
  
  return query;
};

/**
 * Get Urgency Sort Weight
 */
export const getUrgencySortValue = (urgency) => {
  const weights = {
    'emergency': 3,
    'urgent': 2,
    'routine': 1
  };
  return weights[urgency] || 1;
};

/**
 * Format Specialist Info
 */
export const formatSpecialistInfo = (doctor, distance = null) => {
  return {
    id: doctor._id,
    name: `Dr. ${doctor.firstName} ${doctor.lastName}`,
    specialty: doctor.specialty,
    subSpecialty: doctor.subSpecialty || null,
    clinicName: doctor.clinicName || null,
    clinicAddress: doctor.clinicAddress || null,
    distance: distance,
    rating: doctor.rating || 0,
    yearsOfExperience: doctor.yearsOfExperience || 0,
    consultationFee: doctor.consultationFee || 0,
    photoUrl: doctor.photoUrl || null
  };
};
