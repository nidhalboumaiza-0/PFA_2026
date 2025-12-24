import { getBaseTemplate } from './base.template.js';

export function getReferralReceivedTemplate(data) {
  const { 
    doctorName, 
    referringDoctorName, 
    patientName, 
    specialty, 
    urgency, 
    reason, 
    actionUrl 
  } = data;
  
  const urgencyColor = urgency === 'urgent' ? '#f44336' : urgency === 'high' ? '#ff9800' : '#4caf50';
  const urgencyEmoji = urgency === 'urgent' ? '🔴' : urgency === 'high' ? '🟠' : '🟢';
  
  const content = `
    <div class="email-body">
      <h2>📋 New Referral Received</h2>
      <p>Dear Dr. ${doctorName},</p>
      <p>You have received a new patient referral from <strong>Dr. ${referringDoctorName}</strong>.</p>
      
      <div class="info-box">
        <p><strong>Patient:</strong> ${patientName}</p>
        <p><strong>Specialty Requested:</strong> ${specialty}</p>
        <p><strong>Urgency:</strong> <span style="color: ${urgencyColor}; font-weight: bold;">${urgencyEmoji} ${urgency.toUpperCase()}</span></p>
        ${reason ? `<p><strong>Referral Reason:</strong> ${reason}</p>` : ''}
      </div>
      
      <p>Please review the referral details and schedule an appointment with the patient at your earliest convenience.</p>
      
      <center>
        <a href="${actionUrl}" class="button">View Referral Details</a>
      </center>
      
      <div class="divider"></div>
      <p style="font-size: 13px; color: #666;">
        The patient will be notified once you accept the referral and schedule an appointment.
      </p>
    </div>
  `;
  
  return getBaseTemplate(content);
}

export default { getReferralReceivedTemplate };
