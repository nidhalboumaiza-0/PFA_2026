import { Kafka } from 'kafkajs';
import { createAuditLog } from '../utils/auditHelpers.js';
import { getConfig } from '../../../../shared/index.js';

// Lazy initialization - kafka and consumer will be created in startAuditConsumer()
let kafka = null;
let consumer = null;

/**
 * Initialize Kafka client and consumer (called after bootstrap loads config from Consul)
 */
const initializeKafkaClient = () => {
  if (!kafka) {
    kafka = new Kafka({
      clientId: getConfig('KAFKA_CLIENT_ID', 'audit-service'),
      brokers: [getConfig('KAFKA_BROKERS', 'localhost:9092')],
    });

    consumer = kafka.consumer({
      groupId: getConfig('KAFKA_GROUP_ID', 'audit-service-group'),
    });
  }
};

/**
 * Event to Audit Log Mapping
 */
const EVENT_MAPPINGS = {
  // Authentication Events
  'auth.user.registered': {
    action: 'user.registered',
    actionCategory: 'user_management',
    description: 'New user registered',
    severity: 'info',
  },
  'auth.user.verified': {
    action: 'user.email_verified',
    actionCategory: 'authentication',
    description: 'User email verified',
    severity: 'info',
  },
  'auth.user.logged_in': {
    action: 'user.login',
    actionCategory: 'authentication',
    description: 'User logged in successfully',
    severity: 'info',
  },
  'auth.login.failed': {
    action: 'auth.login_failed',
    actionCategory: 'authentication',
    description: 'Failed login attempt',
    severity: 'warning',
    status: 'failed',
  },
  'auth.password.changed': {
    action: 'user.password_changed',
    actionCategory: 'authentication',
    description: 'User password changed',
    severity: 'info',
  },

  // User Management Events
  'user.profile.updated': {
    action: 'user.profile_updated',
    actionCategory: 'user_management',
    description: 'User profile updated',
    severity: 'info',
  },
  'user.account.deleted': {
    action: 'user.account_deleted',
    actionCategory: 'user_management',
    description: 'User account deleted',
    severity: 'warning',
  },

  // Appointment Events
  'rdv.appointment.created': {
    action: 'appointment.created',
    actionCategory: 'appointment',
    description: 'Appointment requested',
    severity: 'info',
  },
  'rdv.appointment.confirmed': {
    action: 'appointment.confirmed',
    actionCategory: 'appointment',
    description: 'Appointment confirmed by doctor',
    severity: 'info',
  },
  'rdv.appointment.rejected': {
    action: 'appointment.rejected',
    actionCategory: 'appointment',
    description: 'Appointment request rejected',
    severity: 'info',
  },
  'rdv.appointment.cancelled': {
    action: 'appointment.cancelled',
    actionCategory: 'appointment',
    description: 'Appointment cancelled',
    severity: 'info',
  },

  // Consultation Events
  'medical-records.consultation.created': {
    action: 'consultation.created',
    actionCategory: 'consultation',
    description: 'Medical consultation created',
    severity: 'info',
  },
  'medical-records.consultation.accessed': {
    action: 'consultation.accessed',
    actionCategory: 'consultation',
    description: 'Medical consultation accessed',
    severity: 'info',
  },
  'medical-records.consultation.updated': {
    action: 'consultation.updated',
    actionCategory: 'consultation',
    description: 'Medical consultation updated',
    severity: 'info',
  },

  // Prescription Events
  'medical-records.prescription.created': {
    action: 'prescription.created',
    actionCategory: 'prescription',
    description: 'Prescription created',
    severity: 'info',
  },
  'medical-records.prescription.updated': {
    action: 'prescription.updated',
    actionCategory: 'prescription',
    description: 'Prescription updated',
    severity: 'info',
  },

  // Document Events
  'medical-records.document.uploaded': {
    action: 'document.uploaded',
    actionCategory: 'document',
    description: 'Medical document uploaded',
    severity: 'info',
  },
  'medical-records.document.downloaded': {
    action: 'document.downloaded',
    actionCategory: 'document',
    description: 'Medical document downloaded',
    severity: 'info',
  },
  'medical-records.document.deleted': {
    action: 'document.deleted',
    actionCategory: 'document',
    description: 'Medical document deleted',
    severity: 'warning',
  },

  // Referral Events
  'referral.referral.created': {
    action: 'referral.created',
    actionCategory: 'referral',
    description: 'Patient referral created',
    severity: 'info',
  },
  'referral.referral.scheduled': {
    action: 'referral.scheduled',
    actionCategory: 'referral',
    description: 'Referral appointment scheduled',
    severity: 'info',
  },

  // Message Events
  'messaging.message.sent': {
    action: 'message.sent',
    actionCategory: 'message',
    description: 'Message sent',
    severity: 'info',
  },
};

/**
 * Log Kafka event to audit log
 */
const logEventToAudit = async (topic, eventData) => {
  try {
    const mapping = EVENT_MAPPINGS[topic];

    if (!mapping) {
      // console.log(`⚠️  No audit mapping for topic: ${topic}`);
      return;
    }

    // Extract common fields
    const performedBy = eventData.userId || eventData.doctorId || eventData.performedBy;
    const performedByType =
      eventData.userType || eventData.performedByType || (eventData.doctorId ? 'doctor' : 'patient');

    // Build audit log data
    const auditData = {
      action: mapping.action,
      actionCategory: mapping.actionCategory,
      performedBy,
      performedByType,
      description: eventData.description || mapping.description,
      severity: mapping.severity || 'info',
      status: mapping.status || 'success',
    };

    // Add resource information
    if (eventData.resourceType && eventData.resourceId) {
      auditData.resourceType = eventData.resourceType;
      auditData.resourceId = eventData.resourceId;
      auditData.resourceName = eventData.resourceName;
    } else if (eventData.appointmentId) {
      auditData.resourceType = 'appointment';
      auditData.resourceId = eventData.appointmentId;
    } else if (eventData.consultationId) {
      auditData.resourceType = 'consultation';
      auditData.resourceId = eventData.consultationId;
    } else if (eventData.prescriptionId) {
      auditData.resourceType = 'prescription';
      auditData.resourceId = eventData.prescriptionId;
    } else if (eventData.documentId) {
      auditData.resourceType = 'document';
      auditData.resourceId = eventData.documentId;
    } else if (eventData.referralId) {
      auditData.resourceType = 'referral';
      auditData.resourceId = eventData.referralId;
    }

    // Add patient context
    if (eventData.patientId) {
      auditData.patientId = eventData.patientId;
    }

    // Add request metadata if available
    if (eventData.ipAddress) auditData.ipAddress = eventData.ipAddress;
    if (eventData.userAgent) auditData.userAgent = eventData.userAgent;

    // Add change tracking
    if (eventData.changes) auditData.changes = eventData.changes;
    if (eventData.previousData) auditData.previousData = eventData.previousData;
    if (eventData.newData) auditData.newData = eventData.newData;

    // Add metadata
    auditData.metadata = {
      kafkaTopic: topic,
      eventData: eventData,
    };

    // Create audit log
    await createAuditLog(auditData);

    console.log(`✅ Audit log created for event: ${topic}`);
  } catch (error) {
    console.error(`Error logging event ${topic} to audit:`, error);
  }
};

/**
 * Start Kafka consumer for audit logging
 */
export const startAuditConsumer = async () => {
  try {
    // Initialize Kafka client (now that config is loaded from Consul)
    initializeKafkaClient();
    
    await consumer.connect();
    console.log('✅ Audit Kafka consumer connected');

    // Subscribe to all relevant topics
    await consumer.subscribe({
      topics: [
        // Authentication topics
        'auth.user.registered',
        'auth.user.verified',
        'auth.user.logged_in',
        'auth.login.failed',
        'auth.password.changed',
        // User management topics
        'user.profile.updated',
        'user.account.deleted',
        // Appointment topics
        'rdv.appointment.created',
        'rdv.appointment.confirmed',
        'rdv.appointment.rejected',
        'rdv.appointment.cancelled',
        // Medical records topics
        'medical-records.consultation.created',
        'medical-records.consultation.accessed',
        'medical-records.consultation.updated',
        'medical-records.prescription.created',
        'medical-records.prescription.updated',
        'medical-records.document.uploaded',
        'medical-records.document.downloaded',
        'medical-records.document.deleted',
        // Referral topics
        'referral.referral.created',
        'referral.referral.scheduled',
        // Message topics
        'messaging.message.sent',
      ],
      fromBeginning: false,
    });

    console.log('✅ Subscribed to audit topics');

    // Process messages
    await consumer.run({
      eachMessage: async ({ topic, partition, message }) => {
        try {
          const eventData = JSON.parse(message.value.toString());
          await logEventToAudit(topic, eventData);
        } catch (error) {
          console.error(`Error processing message from ${topic}:`, error);
        }
      },
    });

    console.log('✅ Audit Kafka consumer running');
  } catch (error) {
    console.error('Error starting Audit Kafka consumer:', error);
    throw error;
  }
};

/**
 * Disconnect Kafka consumer
 */
export const disconnectConsumer = async () => {
  try {
    await consumer.disconnect();
    console.log('✅ Audit Kafka consumer disconnected');
  } catch (error) {
    console.error('Error disconnecting Audit Kafka consumer:', error);
  }
};
