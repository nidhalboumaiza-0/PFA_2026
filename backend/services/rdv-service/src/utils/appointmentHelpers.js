import TimeSlot from '../models/TimeSlot.js';
import Appointment from '../models/Appointment.js';
import axios from 'axios';
import { cacheGet, cacheSet, getUserServiceUrl } from '../../../../shared/index.js';

// Cache TTL
const DOCTOR_CACHE_TTL = 600; // 10 minutes
const PATIENT_CACHE_TTL = 600; // 10 minutes

/**
 * Fetch doctor profile from user service (cached)
 */
export const fetchDoctorProfile = async (doctorId) => {
  const cacheKey = `rdv_doctor:${doctorId}`;
  
  // Try cache first
  const cached = await cacheGet(cacheKey);
  if (cached) {
    console.log(`📦 Cache HIT: RDV doctor ${doctorId}`);
    return cached;
  }

  try {
    const userServiceUrl = await getUserServiceUrl();
    const response = await axios.get(
      `${userServiceUrl}/api/v1/users/doctors/${doctorId}`
    );
    const doctor = response.data.doctor;
    
    // Cache for 10 minutes
    await cacheSet(cacheKey, doctor, DOCTOR_CACHE_TTL);
    console.log(`💾 Cache SET: RDV doctor ${doctorId}`);
    
    return doctor;
  } catch (error) {
    throw new Error('Doctor not found or inactive');
  }
};

/**
 * Fetch patient profile from user service (cached)
 */
export const fetchPatientProfile = async (patientId) => {
  const cacheKey = `rdv_patient:${patientId}`;
  
  // Try cache first
  const cached = await cacheGet(cacheKey);
  if (cached) {
    console.log(`📦 Cache HIT: RDV patient ${patientId}`);
    return cached;
  }

  try {
    const userServiceUrl = await getUserServiceUrl();
    const response = await axios.get(
      `${userServiceUrl}/api/v1/users/patients/${patientId}`,
      { headers: { 'X-Internal-Service': 'rdv-service' } }
    );
    const patient = response.data.patient;
    
    // Cache for 10 minutes
    await cacheSet(cacheKey, patient, PATIENT_CACHE_TTL);
    console.log(`💾 Cache SET: RDV patient ${patientId}`);
    
    return patient;
  } catch (error) {
    console.error(`Failed to fetch patient ${patientId}:`, error.message);
    return null;
  }
};

/**
 * Check if a time slot is available
 */
export const checkSlotAvailability = async (doctorId, date, time) => {
  const timeSlot = await TimeSlot.findOne({
    doctorId,
    date: {
      $gte: new Date(date).setHours(0, 0, 0, 0),
      $lt: new Date(date).setHours(23, 59, 59, 999)
    }
  });

  if (!timeSlot || !timeSlot.isAvailable) {
    return false;
  }

  return timeSlot.isSlotAvailable(time);
};

/**
 * Book a time slot
 */
export const bookTimeSlot = async (doctorId, date, time, appointmentId) => {
  const timeSlot = await TimeSlot.findOne({
    doctorId,
    date: {
      $gte: new Date(date).setHours(0, 0, 0, 0),
      $lt: new Date(date).setHours(23, 59, 59, 999)
    }
  });

  if (!timeSlot) {
    throw new Error('Time slot not found');
  }

  await timeSlot.bookSlot(time, appointmentId);
  return timeSlot;
};

/**
 * Free a time slot
 */
export const freeTimeSlot = async (doctorId, date, time) => {
  const timeSlot = await TimeSlot.findOne({
    doctorId,
    date: {
      $gte: new Date(date).setHours(0, 0, 0, 0),
      $lt: new Date(date).setHours(23, 59, 59, 999)
    }
  });

  if (timeSlot) {
    await timeSlot.freeSlot(time);
  }
};

/**
 * Check for appointment conflicts
 */
export const checkAppointmentConflict = async (patientId, doctorId, date, time) => {
  const existingAppointment = await Appointment.findOne({
    patientId,
    doctorId,
    appointmentDate: {
      $gte: new Date(date).setHours(0, 0, 0, 0),
      $lt: new Date(date).setHours(23, 59, 59, 999)
    },
    appointmentTime: time,
    status: { $in: ['pending', 'confirmed'] }
  });

  return !!existingAppointment;
};

/**
 * Normalize date to start of day
 */
export const normalizeDateToStartOfDay = (date) => {
  const d = new Date(date);
  d.setHours(0, 0, 0, 0);
  return d;
};

/**
 * Normalize date to end of day
 */
export const normalizeDateToEndOfDay = (date) => {
  const d = new Date(date);
  d.setHours(23, 59, 59, 999);
  return d;
};

/**
 * Check if appointment can be cancelled (at least 2 hours before)
 */
export const canCancelAppointment = (appointmentDate, appointmentTime) => {
  const appointmentDateTime = new Date(appointmentDate);
  const [hours, minutes] = appointmentTime.split(':');
  appointmentDateTime.setHours(parseInt(hours), parseInt(minutes), 0, 0);

  const now = new Date();
  const hoursUntilAppointment = (appointmentDateTime - now) / (1000 * 60 * 60);

  return hoursUntilAppointment >= 2;
};

export default {
  fetchDoctorProfile,
  fetchPatientProfile,
  checkSlotAvailability,
  bookTimeSlot,
  freeTimeSlot,
  checkAppointmentConflict,
  normalizeDateToStartOfDay,
  normalizeDateToEndOfDay,
  canCancelAppointment
};
