import { getBaseTemplate } from './base.template.js';
import { getAppointmentConfirmedTemplate } from './appointmentConfirmed.template.js';
import { getAppointmentReminderTemplate } from './appointmentReminder.template.js';
import { getAppointmentCancelledTemplate } from './appointmentCancelled.template.js';
import { getNewMessageTemplate } from './newMessage.template.js';
import { getReferralReceivedTemplate } from './referralReceived.template.js';
import { getReferralScheduledTemplate } from './referralScheduled.template.js';
import { getPrescriptionCreatedTemplate } from './prescriptionCreated.template.js';
import { getDocumentUploadedTemplate } from './documentUploaded.template.js';
import { getConsultationCreatedTemplate } from './consultationCreated.template.js';
import axios from 'axios';
import { getConfig, getRdvServiceUrl, getReferralServiceUrl } from '../../../../../shared/index.js';

/**
 * Generate HTML email template based on notification type
 * @param {Object} notification - Notification object
 * @param {Object} user - User object with email and name
 * @returns {String} - HTML email template
 */
export async function generateEmailTemplate(notification, user) {
  try {
    // Prepare template data
    const data = await prepareTemplateData(notification, user);
    
    // Select appropriate template based on notification type
    switch (notification.type) {
      case 'appointment_confirmed':
        return getAppointmentConfirmedTemplate(data);
        
      case 'appointment_reminder':
        return getAppointmentReminderTemplate(data);
        
      case 'appointment_cancelled':
        return getAppointmentCancelledTemplate(data);
        
      case 'new_message':
        return getNewMessageTemplate(data);
        
      case 'referral_received':
        return getReferralReceivedTemplate(data);
        
      case 'referral_scheduled':
        return getReferralScheduledTemplate(data);
        
      case 'prescription_created':
        return getPrescriptionCreatedTemplate(data);
        
      case 'document_uploaded':
        return getDocumentUploadedTemplate(data);
        
      case 'consultation_created':
        return getConsultationCreatedTemplate(data);
        
      default:
        // Generic template for other notification types
        return getGenericTemplate(data, notification);
    }
  } catch (error) {
    console.error('Error generating email template:', error);
    // Fallback to generic template
    return getGenericTemplate({ actionUrl: notification.actionUrl }, notification);
  }
}

/**
 * Prepare template data by fetching related resources
 */
async function prepareTemplateData(notification, user) {
  const frontendUrl = getConfig('FRONTEND_URL', 'http://localhost:3000');
  
  const data = {
    patientName: `${user.firstName} ${user.lastName}`,
    recipientName: `${user.firstName} ${user.lastName}`,
    actionUrl: `${frontendUrl}${notification.actionUrl || '/'}`
  };
  
  // Fetch resource-specific data if available
  if (notification.relatedResource) {
    const { resourceType, resourceId } = notification.relatedResource;
    
    try {
      switch (resourceType) {
        case 'appointment':
          const appointmentData = await fetchAppointmentData(resourceId);
          Object.assign(data, appointmentData);
          break;
          
        case 'referral':
          const referralData = await fetchReferralData(resourceId);
          Object.assign(data, referralData);
          break;
          
        case 'prescription':
          const prescriptionData = await fetchPrescriptionData(resourceId);
          Object.assign(data, prescriptionData);
          break;
          
        case 'document':
          const documentData = await fetchDocumentData(resourceId);
          Object.assign(data, documentData);
          break;
          
        case 'consultation':
          const consultationData = await fetchConsultationData(resourceId);
          Object.assign(data, consultationData);
          break;
          
        case 'message':
          const messageData = await fetchMessageData(resourceId);
          Object.assign(data, messageData);
          break;
      }
    } catch (error) {
      console.error(`Error fetching ${resourceType} data:`, error.message);
      // Continue with basic data
    }
  }
  
  // Extract additional data from actionData if available
  if (notification.actionData) {
    Object.assign(data, notification.actionData);
  }
  
  return data;
}

/**
 * Fetch appointment data
 */
async function fetchAppointmentData(appointmentId) {
  try {
    const rdvServiceUrl = await getRdvServiceUrl();
    const response = await axios.get(
      `${rdvServiceUrl}/api/v1/rdv/appointments/${appointmentId}`,
      { timeout: 5000 }
    );
    
    const appointment = response.data.data;
    const doctor = appointment.doctor;
    
    return {
      doctorName: `${doctor.firstName} ${doctor.lastName}`,
      appointmentDate: appointment.appointmentDate,
      appointmentTime: appointment.time,
      clinicName: doctor.clinicName,
      clinicAddress: doctor.clinicAddress,
      cancellationReason: appointment.cancellationReason
    };
  } catch (error) {
    console.error('Error fetching appointment:', error.message);
    return {};
  }
}

/**
 * Fetch referral data
 */
async function fetchReferralData(referralId) {
  try {
    const referralServiceUrl = await getReferralServiceUrl();
    const response = await axios.get(
      `${referralServiceUrl}/api/v1/referrals/${referralId}`,
      { timeout: 5000 }
    );
    
    const referral = response.data.data;
    
    return {
      referringDoctorName: `${referral.referringDoctor.firstName} ${referral.referringDoctor.lastName}`,
      doctorName: `${referral.targetDoctor.firstName} ${referral.targetDoctor.lastName}`,
      patientName: `${referral.patient.firstName} ${referral.patient.lastName}`,
      specialty: referral.specialty,
      urgency: referral.urgency,
      reason: referral.reason
    };
  } catch (error) {
    console.error('Error fetching referral:', error.message);
    return {};
  }
}

/**
 * Fetch prescription data
 */
async function fetchPrescriptionData(prescriptionId) {
  try {
    // Prescription data might be in actionData already
    return {};
  } catch (error) {
    return {};
  }
}

/**
 * Fetch document data
 */
async function fetchDocumentData(documentId) {
  try {
    // Document data might be in actionData already
    return {};
  } catch (error) {
    return {};
  }
}

/**
 * Fetch consultation data
 */
async function fetchConsultationData(consultationId) {
  try {
    // Consultation data might be in actionData already
    return {};
  } catch (error) {
    return {};
  }
}

/**
 * Fetch message data
 */
async function fetchMessageData(messageId) {
  try {
    // Message data might be in actionData already
    return {};
  } catch (error) {
    return {};
  }
}

/**
 * Generic email template for unsupported notification types
 */
function getGenericTemplate(data, notification) {
  const content = `
    <div class="email-body">
      <h2>📬 ${notification.title}</h2>
      <p>${notification.body}</p>
      
      ${data.actionUrl ? `
        <center>
          <a href="${data.actionUrl}" class="button">View Details</a>
        </center>
      ` : ''}
    </div>
  `;
  
  return getBaseTemplate(content);
}

export default { generateEmailTemplate };
