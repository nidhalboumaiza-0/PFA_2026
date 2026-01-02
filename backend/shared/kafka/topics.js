/**
 * Kafka Topics Definition
 * Naming convention: service.entity.action
 */

const TOPICS = {
  // Auth Service Events
  AUTH: {
    USER_REGISTERED: 'auth.user.registered',
    USER_VERIFIED: 'auth.user.verified',
    USER_LOGIN: 'auth.user.login',
    PASSWORD_RESET: 'auth.password.reset',
    TOKEN_REFRESHED: 'auth.token.refreshed'
  },

  // User Service Events
  USER: {
    PROFILE_CREATED: 'user.profile.created',
    PROFILE_UPDATED: 'user.profile.updated',
    PHOTO_UPLOADED: 'user.photo.uploaded',
    DOCTOR_VERIFIED: 'user.doctor.verified'
  },

  // Appointment Service Events
  RDV: {
    AVAILABILITY_SET: 'rdv.availability.set',
    APPOINTMENT_REQUESTED: 'rdv.appointment.requested',
    APPOINTMENT_CONFIRMED: 'rdv.appointment.confirmed',
    APPOINTMENT_REJECTED: 'rdv.appointment.rejected',
    APPOINTMENT_CANCELLED: 'rdv.appointment.cancelled',
    APPOINTMENT_COMPLETED: 'rdv.appointment.completed',
    APPOINTMENT_REMINDER: 'rdv.appointment.reminder',
    APPOINTMENT_RESCHEDULED: 'rdv.appointment.rescheduled',
    RESCHEDULE_REQUESTED: 'rdv.reschedule.requested',
    RESCHEDULE_APPROVED: 'rdv.reschedule.approved',
    RESCHEDULE_REJECTED: 'rdv.reschedule.rejected',
    REFERRAL_BOOKED: 'rdv.referral.booked',
    REVIEW_CREATED: 'rdv.review.created',
    DOCTOR_RATING_UPDATED: 'rdv.doctor.rating.updated'
  },

  // Medical Records Events
  MEDICAL: {
    CONSULTATION_CREATED: 'medical.consultation.created',
    CONSULTATION_UPDATED: 'medical.consultation.updated',
    CONSULTATION_ACCESSED: 'medical.consultation.accessed',
    PRESCRIPTION_CREATED: 'medical.prescription.created',
    PRESCRIPTION_UPDATED: 'medical.prescription.updated',
    PRESCRIPTION_LOCKED: 'medical.prescription.locked',
    PRESCRIPTION_ACCESSED: 'medical.prescription.accessed',
    DOCUMENT_UPLOADED: 'medical.document.uploaded',
    DOCUMENT_UPDATED: 'medical.document.updated',
    DOCUMENT_DELETED: 'medical.document.deleted',
    DOCUMENT_SHARED: 'medical.document.shared',
    DOCUMENT_ACCESSED: 'medical.document.accessed'
  },

  // Referral Service Events
  REFERRAL: {
    REFERRAL_CREATED: 'referral.referral.created',
    REFERRAL_SCHEDULED: 'referral.referral.scheduled',
    REFERRAL_ACCEPTED: 'referral.referral.accepted',
    REFERRAL_REJECTED: 'referral.referral.rejected',
    REFERRAL_COMPLETED: 'referral.referral.completed',
    REFERRAL_CANCELLED: 'referral.referral.cancelled'
  },
  
  // Messaging Service Events
  MESSAGE: {
    CONVERSATION_CREATED: 'messaging.conversation.created',
    MESSAGE_SENT: 'messaging.message.sent',
    MESSAGE_DELIVERED: 'messaging.message.delivered',
    MESSAGE_READ: 'messaging.message.read'
  },

  // Notification Events
  NOTIFICATION: {
    PUSH_SENT: 'notification.push.sent',
    EMAIL_SENT: 'notification.email.sent',
    SMS_SENT: 'notification.sms.sent'
  },

  // Audit Events
  AUDIT: {
    ACTION_LOGGED: 'audit.action.logged',
    SECURITY_EVENT: 'audit.security.event'
  }
};

// Named export for compatibility
export const KAFKA_TOPICS = TOPICS;

// Default export
export default TOPICS;
