import kafkaProducer from './producer.js';
import TOPICS from './topics.js';
import { createEvent } from './schemas.js';

/**
 * Emit user registered event
 */
export const emitUserRegistered = async (userId, email, role) => {
  const event = createEvent('auth.user.registered', {
    userId,
    email,
    role
  });
  await kafkaProducer.sendEvent(TOPICS.AUTH.USER_REGISTERED, event);
};

/**
 * Emit appointment confirmed event
 */
export const emitAppointmentConfirmed = async (appointmentData) => {
  const event = createEvent('rdv.appointment.confirmed', appointmentData);
  await kafkaProducer.sendEvent(TOPICS.RDV.APPOINTMENT_CONFIRMED, event);
};

/**
 * Emit consultation created event
 */
export const emitConsultationCreated = async (consultationData) => {
  const event = createEvent('medical.consultation.created', consultationData);
  await kafkaProducer.sendEvent(TOPICS.MEDICAL.CONSULTATION_CREATED, event);
};

/**
 * Emit prescription created event
 */
export const emitPrescriptionCreated = async (prescriptionData) => {
  const event = createEvent('medical.prescription.created', prescriptionData);
  await kafkaProducer.sendEvent(TOPICS.MEDICAL.PRESCRIPTION_CREATED, event);
};

/**
 * Emit referral created event
 */
export const emitReferralCreated = async (referralData) => {
  const event = createEvent('referral.referral.created', referralData);
  await kafkaProducer.sendEvent(TOPICS.REFERRAL.REFERRAL_CREATED, event);
};

/**
 * Emit message sent event
 */
export const emitMessageSent = async (messageData) => {
  const event = createEvent('messaging.message.sent', messageData);
  await kafkaProducer.sendEvent(TOPICS.MESSAGING.MESSAGE_SENT, event);
};
