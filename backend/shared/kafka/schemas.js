/**
 * Event Schema Templates
 * These define the structure of events sent through Kafka
 */

export const EVENT_SCHEMAS = {
  // User Registration Event
  USER_REGISTERED: {
    eventType: 'auth.user.registered',
    eventId: 'uuid',
    userId: 'string',
    email: 'string',
    role: 'string', // 'patient' | 'doctor' | 'admin'
    timestamp: 'ISO date string'
  },

  // User Verified Event
  USER_VERIFIED: {
    eventType: 'auth.user.verified',
    eventId: 'uuid',
    userId: 'string',
    email: 'string',
    timestamp: 'ISO date string'
  },

  // Appointment Requested Event
  APPOINTMENT_REQUESTED: {
    eventType: 'rdv.appointment.requested',
    eventId: 'uuid',
    appointmentId: 'string',
    patientId: 'string',
    doctorId: 'string',
    date: 'ISO date string',
    timeSlot: 'string',
    reason: 'string',
    timestamp: 'ISO date string'
  },

  // Appointment Confirmed Event
  APPOINTMENT_CONFIRMED: {
    eventType: 'rdv.appointment.confirmed',
    eventId: 'uuid',
    appointmentId: 'string',
    patientId: 'string',
    doctorId: 'string',
    date: 'ISO date string',
    timeSlot: 'string',
    timestamp: 'ISO date string'
  },

  // Consultation Created Event
  CONSULTATION_CREATED: {
    eventType: 'medical.consultation.created',
    eventId: 'uuid',
    consultationId: 'string',
    patientId: 'string',
    doctorId: 'string',
    appointmentId: 'string',
    diagnosis: 'string',
    timestamp: 'ISO date string'
  },

  // Prescription Created Event
  PRESCRIPTION_CREATED: {
    eventType: 'medical.prescription.created',
    eventId: 'uuid',
    prescriptionId: 'string',
    patientId: 'string',
    doctorId: 'string',
    consultationId: 'string',
    medicationCount: 'number',
    canEditUntil: 'ISO date string',
    timestamp: 'ISO date string'
  },

  // Document Uploaded Event
  DOCUMENT_UPLOADED: {
    eventType: 'medical.document.uploaded',
    eventId: 'uuid',
    documentId: 'string',
    patientId: 'string',
    doctorId: 'string',
    documentType: 'string',
    fileSize: 'number',
    timestamp: 'ISO date string'
  },

  // Referral Created Event
  REFERRAL_CREATED: {
    eventType: 'referral.referral.created',
    eventId: 'uuid',
    referralId: 'string',
    patientId: 'string',
    fromDoctorId: 'string',
    toDoctorId: 'string',
    specialty: 'string',
    urgency: 'string',
    timestamp: 'ISO date string'
  },

  // Message Sent Event
  MESSAGE_SENT: {
    eventType: 'messaging.message.sent',
    eventId: 'uuid',
    messageId: 'string',
    conversationId: 'string',
    senderId: 'string',
    receiverId: 'string',
    messageType: 'string',
    timestamp: 'ISO date string'
  }
};

/**
 * Create event with schema validation
 */
export const createEvent = (eventType, data) => {
  return {
    eventType,
    eventId: generateEventId(),
    ...data,
    timestamp: new Date().toISOString()
  };
};

/**
 * Generate unique event ID
 */
export const generateEventId = () => {
  return `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
};
