import { Kafka } from 'kafkajs';
import { createNotification } from '../services/notificationService.js';
import { getDoctorById, getPatientById, getAppointmentById } from '../utils/helpers.js';
import { getConfig } from '../../../../shared/index.js';

// Lazy initialization - kafka and consumer will be created in startNotificationConsumer()
let kafka = null;
let consumer = null;

/**
 * Initialize Kafka client and consumer (called after bootstrap loads config from Consul)
 */
const initializeKafkaClient = () => {
  if (!kafka) {
    kafka = new Kafka({
      clientId: getConfig('KAFKA_CLIENT_ID', 'notification-service'),
      brokers: [getConfig('KAFKA_BROKERS', 'localhost:9092')],
    });

    consumer = kafka.consumer({
      groupId: getConfig('KAFKA_GROUP_ID', 'notification-service-group'),
    });
  }
};

/**
 * Handle appointment confirmed event
 */
const handleAppointmentConfirmed = async (event) => {
  try {
    const { appointmentId, patientId, doctorId, scheduledDate } = event;

    // Fetch doctor and patient details
    const doctor = await getDoctorById(doctorId);
    const doctorName = doctor ? `Dr. ${doctor.firstName} ${doctor.lastName}` : 'your doctor';

    // Format date
    const date = new Date(scheduledDate);
    const dateStr = date.toLocaleDateString('fr-FR', {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric',
    });
    const timeStr = date.toLocaleTimeString('fr-FR', {
      hour: '2-digit',
      minute: '2-digit',
    });

    // Create notification for patient
    await createNotification({
      userId: patientId,
      userType: 'patient',
      title: 'Rendez-vous confirmé',
      body: `Votre rendez-vous avec ${doctorName} a été confirmé pour le ${dateStr} à ${timeStr}.`,
      type: 'appointment_confirmed',
      relatedResource: {
        resourceType: 'appointment',
        resourceId: appointmentId,
      },
      priority: 'high',
      actionUrl: `/appointments/${appointmentId}`,
      actionData: {
        appointmentId,
        doctorId,
        scheduledDate,
      },
    });

    console.log(`✅ Appointment confirmed notification sent to patient ${patientId}`);
  } catch (error) {
    console.error('Error handling appointment confirmed:', error);
  }
};

/**
 * Handle appointment rejected event
 */
const handleAppointmentRejected = async (event) => {
  try {
    const { appointmentId, patientId, doctorId, reason } = event;

    const doctor = await getDoctorById(doctorId);
    const doctorName = doctor ? `Dr. ${doctor.firstName} ${doctor.lastName}` : 'le médecin';

    await createNotification({
      userId: patientId,
      userType: 'patient',
      title: 'Rendez-vous refusé',
      body: `Votre demande de rendez-vous avec ${doctorName} a été refusée. ${reason ? `Raison: ${reason}` : ''
        }`,
      type: 'appointment_rejected',
      relatedResource: {
        resourceType: 'appointment',
        resourceId: appointmentId,
      },
      priority: 'medium',
      actionUrl: '/appointments/search',
      actionData: {
        appointmentId,
        doctorId,
        reason,
      },
    });

    console.log(`✅ Appointment rejected notification sent to patient ${patientId}`);
  } catch (error) {
    console.error('Error handling appointment rejected:', error);
  }
};

/**
 * Handle appointment cancelled event
 */
const handleAppointmentCancelled = async (event) => {
  try {
    const { appointmentId, patientId, doctorId, cancelledBy, reason } = event;

    // Determine who to notify
    const notifyUserId = cancelledBy === 'patient' ? doctorId : patientId;
    const notifyUserType = cancelledBy === 'patient' ? 'doctor' : 'patient';

    // Get canceller's name
    let cancellerName = 'L\'autre partie';
    if (cancelledBy === 'patient') {
      const patient = await getPatientById(patientId);
      cancellerName = patient ? `${patient.firstName} ${patient.lastName}` : 'Le patient';
    } else {
      const doctor = await getDoctorById(doctorId);
      cancellerName = doctor ? `Dr. ${doctor.firstName} ${doctor.lastName}` : 'Le médecin';
    }

    await createNotification({
      userId: notifyUserId,
      userType: notifyUserType,
      title: 'Rendez-vous annulé',
      body: `${cancellerName} a annulé le rendez-vous. ${reason ? `Raison: ${reason}` : ''}`,
      type: 'appointment_cancelled',
      relatedResource: {
        resourceType: 'appointment',
        resourceId: appointmentId,
      },
      priority: 'high',
      actionUrl: `/appointments/${appointmentId}`,
      actionData: {
        appointmentId,
        cancelledBy,
        reason,
      },
    });

    console.log(`✅ Appointment cancelled notification sent to ${notifyUserType} ${notifyUserId}`);
  } catch (error) {
    console.error('Error handling appointment cancelled:', error);
  }
};

/**
 * Handle appointment reminder (scheduled 24h before)
 */
const handleAppointmentReminder = async (event) => {
  try {
    const { appointmentId, patientId, doctorId, scheduledDate } = event;

    const doctor = await getDoctorById(doctorId);
    const doctorName = doctor ? `Dr. ${doctor.firstName} ${doctor.lastName}` : 'votre médecin';

    // Calculate reminder time (24 hours before)
    const appointmentDate = new Date(scheduledDate);
    const reminderDate = new Date(appointmentDate.getTime() - 24 * 60 * 60 * 1000);

    const dateStr = appointmentDate.toLocaleDateString('fr-FR', {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric',
    });
    const timeStr = appointmentDate.toLocaleTimeString('fr-FR', {
      hour: '2-digit',
      minute: '2-digit',
    });

    // Create scheduled notification
    await createNotification({
      userId: patientId,
      userType: 'patient',
      title: 'Rappel de rendez-vous',
      body: `N'oubliez pas votre rendez-vous avec ${doctorName} demain le ${dateStr} à ${timeStr}.`,
      type: 'appointment_reminder',
      relatedResource: {
        resourceType: 'appointment',
        resourceId: appointmentId,
      },
      priority: 'high',
      actionUrl: `/appointments/${appointmentId}`,
      actionData: {
        appointmentId,
        doctorId,
        scheduledDate,
      },
      scheduledFor: reminderDate,
    });

    console.log(
      `✅ Appointment reminder scheduled for patient ${patientId} at ${reminderDate.toISOString()}`
    );
  } catch (error) {
    console.error('Error handling appointment reminder:', error);
  }
};

/**
 * Handle new message event
 */
const handleNewMessage = async (event) => {
  try {
    const { conversationId, senderId, receiverId, senderName, isReceiverOnline } = event;

    // Only send notification if receiver is offline
    if (isReceiverOnline) {
      console.log(`⏩ Skipping notification - receiver ${receiverId} is online`);
      return;
    }

    await createNotification({
      userId: receiverId,
      userType: 'patient', // Will be overridden by actual user type
      title: 'Nouveau message',
      body: `Vous avez reçu un nouveau message de ${senderName}`,
      type: 'new_message',
      relatedResource: {
        resourceType: 'message',
        resourceId: conversationId,
      },
      priority: 'medium',
      actionUrl: `/messages/${conversationId}`,
      actionData: {
        conversationId,
        senderId,
      },
    });

    console.log(`✅ New message notification sent to ${receiverId}`);
  } catch (error) {
    console.error('Error handling new message:', error);
  }
};

/**
 * Handle referral created event
 */
const handleReferralReceived = async (event) => {
  try {
    const { referralId, referringDoctorId, targetDoctorId, patientId, specialty } = event;

    const referringDoctor = await getDoctorById(referringDoctorId);
    const doctorName = referringDoctor
      ? `Dr. ${referringDoctor.firstName} ${referringDoctor.lastName}`
      : 'un confrère';

    // Notify target doctor
    await createNotification({
      userId: targetDoctorId,
      userType: 'doctor',
      title: 'Nouvelle orientation reçue',
      body: `Vous avez reçu une nouvelle orientation de ${doctorName} pour un patient en ${specialty}.`,
      type: 'referral_received',
      relatedResource: {
        resourceType: 'referral',
        resourceId: referralId,
      },
      priority: 'high',
      actionUrl: `/referrals/${referralId}`,
      actionData: {
        referralId,
        referringDoctorId,
        patientId,
        specialty,
      },
    });

    console.log(`✅ Referral received notification sent to doctor ${targetDoctorId}`);
  } catch (error) {
    console.error('Error handling referral received:', error);
  }
};

/**
 * Handle referral scheduled event
 */
const handleReferralScheduled = async (event) => {
  try {
    const { referralId, patientId, targetDoctorId, appointmentId, scheduledDate } = event;

    const doctor = await getDoctorById(targetDoctorId);
    const doctorName = doctor ? `Dr. ${doctor.firstName} ${doctor.lastName}` : 'le spécialiste';

    const date = new Date(scheduledDate);
    const dateStr = date.toLocaleDateString('fr-FR', {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric',
    });
    const timeStr = date.toLocaleTimeString('fr-FR', {
      hour: '2-digit',
      minute: '2-digit',
    });

    // Notify patient
    await createNotification({
      userId: patientId,
      userType: 'patient',
      title: 'Rendez-vous d\'orientation planifié',
      body: `Votre rendez-vous avec ${doctorName} a été planifié pour le ${dateStr} à ${timeStr}.`,
      type: 'referral_scheduled',
      relatedResource: {
        resourceType: 'referral',
        resourceId: referralId,
      },
      priority: 'high',
      actionUrl: `/appointments/${appointmentId}`,
      actionData: {
        referralId,
        appointmentId,
        targetDoctorId,
        scheduledDate,
      },
    });

    console.log(`✅ Referral scheduled notification sent to patient ${patientId}`);
  } catch (error) {
    console.error('Error handling referral scheduled:', error);
  }
};

/**
 * Handle consultation created event
 */
const handleConsultationCreated = async (event) => {
  try {
    const { consultationId, patientId, doctorId, diagnosis, chiefComplaint, consultationDate } = event;

    const doctor = await getDoctorById(doctorId);
    const doctorName = doctor ? `Dr. ${doctor.firstName} ${doctor.lastName}` : 'votre médecin';

    // Notify patient
    await createNotification({
      userId: patientId,
      userType: 'patient',
      title: 'Nouvelle consultation enregistrée',
      body: `${doctorName} a enregistré les détails de votre consultation dans vos dossiers médicaux.`,
      type: 'consultation_created',
      relatedResource: {
        resourceType: 'consultation',
        resourceId: consultationId,
      },
      priority: 'medium',
      actionUrl: `/consultations/${consultationId}`,
      actionData: {
        consultationId,
        doctorId,
        diagnosis,
        chiefComplaint,
        consultationDate,
        doctorName,
      },
    });

    console.log(`✅ Consultation created notification sent to patient ${patientId}`);
  } catch (error) {
    console.error('Error handling consultation created:', error);
  }
};

/**
 * Handle prescription created event
 */
const handlePrescriptionCreated = async (event) => {
  try {
    const { prescriptionId, patientId, doctorId, medicationCount, medications } = event;

    const doctor = await getDoctorById(doctorId);
    const doctorName = doctor ? `Dr. ${doctor.firstName} ${doctor.lastName}` : 'votre médecin';

    // Notify patient
    await createNotification({
      userId: patientId,
      userType: 'patient',
      title: 'Nouvelle ordonnance',
      body: `${doctorName} a créé une nouvelle ordonnance avec ${medicationCount} médicament${medicationCount > 1 ? 's' : ''}.`,
      type: 'prescription_created',
      relatedResource: {
        resourceType: 'prescription',
        resourceId: prescriptionId,
      },
      priority: 'high',
      actionUrl: `/prescriptions/${prescriptionId}`,
      actionData: {
        prescriptionId,
        doctorId,
        medicationCount,
        medications: medications || [],
        doctorName,
      },
    });

    console.log(`✅ Prescription created notification sent to patient ${patientId}`);
  } catch (error) {
    console.error('Error handling prescription created:', error);
  }
};

/**
 * Handle prescription updated event
 */
const handlePrescriptionUpdated = async (event) => {
  try {
    const { prescriptionId, patientId, doctorId, modificationType } = event;

    const doctor = await getDoctorById(doctorId);
    const doctorName = doctor ? `Dr. ${doctor.firstName} ${doctor.lastName}` : 'votre médecin';

    // Notify patient
    await createNotification({
      userId: patientId,
      userType: 'patient',
      title: 'Ordonnance modifiée',
      body: `${doctorName} a modifié votre ordonnance. Veuillez consulter les changements.`,
      type: 'prescription_updated',
      relatedResource: {
        resourceType: 'prescription',
        resourceId: prescriptionId,
      },
      priority: 'high',
      actionUrl: `/prescriptions/${prescriptionId}`,
      actionData: {
        prescriptionId,
        doctorId,
        modificationType,
        doctorName,
      },
    });

    console.log(`✅ Prescription updated notification sent to patient ${patientId}`);
  } catch (error) {
    console.error('Error handling prescription updated:', error);
  }
};

/**
 * Handle document uploaded event
 */
const handleDocumentUploaded = async (event) => {
  try {
    const { documentId, patientId, uploadedBy, uploaderType, documentTitle, documentType } = event;

    let uploaderName = 'Un professionnel de santé';

    if (uploaderType === 'doctor') {
      const doctor = await getDoctorById(uploadedBy);
      uploaderName = doctor ? `Dr. ${doctor.firstName} ${doctor.lastName}` : 'Votre médecin';
    } else if (uploaderType === 'patient') {
      const patient = await getPatientById(uploadedBy);
      uploaderName = patient ? 'Vous' : 'Un patient';
    }

    // Notify patient (only if not self-uploaded)
    if (uploadedBy.toString() !== patientId.toString()) {
      await createNotification({
        userId: patientId,
        userType: 'patient',
        title: 'Nouveau document médical',
        body: `${uploaderName} a téléchargé un nouveau document : ${documentTitle}`,
        type: 'document_uploaded',
        relatedResource: {
          resourceType: 'document',
          resourceId: documentId,
        },
        priority: 'medium',
        actionUrl: `/documents/${documentId}`,
        actionData: {
          documentId,
          uploadedBy,
          uploaderType,
          documentTitle,
          documentType,
          uploaderName,
        },
      });

      console.log(`✅ Document uploaded notification sent to patient ${patientId}`);
    }
  } catch (error) {
    console.error('Error handling document uploaded:', error);
  }
};

/**
 * Handle appointment rescheduled event (by doctor - notify patient)
 */
const handleAppointmentRescheduled = async (event) => {
  try {
    const { appointmentId, patientId, doctorId, previousDate, previousTime, newDate, newTime, rescheduledBy, reason } = event;

    // If rescheduled by doctor, notify patient
    if (rescheduledBy === 'doctor') {
      const doctor = await getDoctorById(doctorId);
      const doctorName = doctor ? `Dr. ${doctor.firstName} ${doctor.lastName}` : 'Votre médecin';

      const newDateObj = new Date(newDate);
      const dateStr = newDateObj.toLocaleDateString('fr-FR', {
        weekday: 'long',
        year: 'numeric',
        month: 'long',
        day: 'numeric',
      });

      await createNotification({
        userId: patientId,
        userType: 'patient',
        title: 'Rendez-vous reprogrammé',
        body: `${doctorName} a reprogrammé votre rendez-vous au ${dateStr} à ${newTime}. ${reason ? `Raison: ${reason}` : ''}`,
        type: 'appointment_rescheduled',
        relatedResource: {
          resourceType: 'appointment',
          resourceId: appointmentId,
        },
        priority: 'high',
        actionUrl: `/appointments/${appointmentId}`,
        actionData: {
          appointmentId,
          doctorId,
          previousDate,
          previousTime,
          newDate,
          newTime,
          reason,
        },
      });

      console.log(`✅ Appointment rescheduled notification sent to patient ${patientId}`);
    }
    // If reschedule was approved (patient requested), notify patient of approval
    else if (rescheduledBy === 'patient') {
      const doctor = await getDoctorById(doctorId);
      const doctorName = doctor ? `Dr. ${doctor.firstName} ${doctor.lastName}` : 'Le médecin';

      const newDateObj = new Date(newDate);
      const dateStr = newDateObj.toLocaleDateString('fr-FR', {
        weekday: 'long',
        year: 'numeric',
        month: 'long',
        day: 'numeric',
      });

      await createNotification({
        userId: patientId,
        userType: 'patient',
        title: 'Demande de report acceptée',
        body: `${doctorName} a accepté votre demande de report. Nouveau rendez-vous le ${dateStr} à ${newTime}.`,
        type: 'reschedule_approved',
        relatedResource: {
          resourceType: 'appointment',
          resourceId: appointmentId,
        },
        priority: 'high',
        actionUrl: `/appointments/${appointmentId}`,
        actionData: {
          appointmentId,
          doctorId,
          newDate,
          newTime,
        },
      });

      console.log(`✅ Reschedule approved notification sent to patient ${patientId}`);
    }
  } catch (error) {
    console.error('Error handling appointment rescheduled:', error);
  }
};

/**
 * Handle reschedule requested event (by patient - notify doctor)
 */
const handleRescheduleRequested = async (event) => {
  try {
    const { appointmentId, patientId, doctorId, currentDate, currentTime, requestedDate, requestedTime, reason } = event;

    const patient = await getPatientById(patientId);
    const patientName = patient ? `${patient.firstName} ${patient.lastName}` : 'Un patient';

    const requestedDateObj = new Date(requestedDate);
    const dateStr = requestedDateObj.toLocaleDateString('fr-FR', {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric',
    });

    await createNotification({
      userId: doctorId,
      userType: 'doctor',
      title: 'Demande de report de rendez-vous',
      body: `${patientName} demande à reporter son rendez-vous au ${dateStr} à ${requestedTime}. ${reason ? `Raison: ${reason}` : ''}`,
      type: 'reschedule_requested',
      relatedResource: {
        resourceType: 'appointment',
        resourceId: appointmentId,
      },
      priority: 'high',
      actionUrl: `/appointments/${appointmentId}`,
      actionData: {
        appointmentId,
        patientId,
        currentDate,
        currentTime,
        requestedDate,
        requestedTime,
        reason,
      },
    });

    console.log(`✅ Reschedule request notification sent to doctor ${doctorId}`);
  } catch (error) {
    console.error('Error handling reschedule requested:', error);
  }
};

/**
 * Handle reschedule rejected event (notify patient)
 */
const handleRescheduleRejected = async (event) => {
  try {
    const { appointmentId, patientId, doctorId, reason } = event;

    const doctor = await getDoctorById(doctorId);
    const doctorName = doctor ? `Dr. ${doctor.firstName} ${doctor.lastName}` : 'Le médecin';

    await createNotification({
      userId: patientId,
      userType: 'patient',
      title: 'Demande de report refusée',
      body: `${doctorName} a refusé votre demande de report de rendez-vous. ${reason ? `Raison: ${reason}` : 'Veuillez conserver la date initiale ou annuler.'}`,
      type: 'reschedule_rejected',
      relatedResource: {
        resourceType: 'appointment',
        resourceId: appointmentId,
      },
      priority: 'medium',
      actionUrl: `/appointments/${appointmentId}`,
      actionData: {
        appointmentId,
        doctorId,
        reason,
      },
    });

    console.log(`✅ Reschedule rejected notification sent to patient ${patientId}`);
  } catch (error) {
    console.error('Error handling reschedule rejected:', error);
  }
};

/**
 * Route event to appropriate handler
 */
const handleEvent = async (topic, event) => {
  const handlers = {
    'rdv.appointment.confirmed': handleAppointmentConfirmed,
    'rdv.appointment.rejected': handleAppointmentRejected,
    'rdv.appointment.cancelled': handleAppointmentCancelled,
    'rdv.appointment.reminder': handleAppointmentReminder,
    'rdv.appointment.rescheduled': handleAppointmentRescheduled,
    'rdv.reschedule.requested': handleRescheduleRequested,
    'rdv.reschedule.rejected': handleRescheduleRejected,
    'messaging.message.sent': handleNewMessage,
    'referral.referral.created': handleReferralReceived,
    'referral.referral.scheduled': handleReferralScheduled,
    'medical-records.consultation.created': handleConsultationCreated,
    'medical-records.prescription.created': handlePrescriptionCreated,
    'medical-records.prescription.updated': handlePrescriptionUpdated,
    'medical-records.document.uploaded': handleDocumentUploaded,
  };

  const handler = handlers[topic];

  if (handler) {
    await handler(event);
  } else {
    console.log(`⚠️  No handler found for topic: ${topic}`);
  }
};

/**
 * Start Kafka consumer
 */
export const startNotificationConsumer = async () => {
  try {
    // Initialize Kafka client (now that config is loaded from Consul)
    initializeKafkaClient();

    await consumer.connect();
    console.log('✅ Kafka consumer connected');

    // Subscribe to topics
    await consumer.subscribe({
      topics: [
        'rdv.appointment.confirmed',
        'rdv.appointment.rejected',
        'rdv.appointment.cancelled',
        'rdv.appointment.reminder',
        'rdv.appointment.rescheduled',
        'rdv.reschedule.requested',
        'rdv.reschedule.rejected',
        'messaging.message.sent',
        'referral.referral.created',
        'referral.referral.scheduled',
        'medical-records.consultation.created',
        'medical-records.prescription.created',
        'medical-records.prescription.updated',
        'medical-records.document.uploaded',
      ],
      fromBeginning: false,
    });

    console.log('✅ Subscribed to notification topics');

    // Process messages
    await consumer.run({
      eachMessage: async ({ topic, partition, message }) => {
        try {
          const event = JSON.parse(message.value.toString());
          console.log(`📨 Received event from ${topic}:`, event);
          await handleEvent(topic, event);
        } catch (error) {
          console.error(`Error processing message from ${topic}:`, error);
        }
      },
    });

    console.log('✅ Kafka consumer running');
  } catch (error) {
    console.error('Error starting Kafka consumer:', error);
    throw error;
  }
};

/**
 * Disconnect Kafka consumer
 */
export const disconnectConsumer = async () => {
  try {
    await consumer.disconnect();
    console.log('✅ Kafka consumer disconnected');
  } catch (error) {
    console.error('Error disconnecting Kafka consumer:', error);
  }
};
