import { getBaseTemplate } from './base.template.js';

export function getReferralScheduledTemplate(data) {
  const { 
    patientName, 
    doctorName, 
    specialty, 
    appointmentDate, 
    appointmentTime, 
    clinicAddress,
    actionUrl 
  } = data;
  
  const formattedDate = new Date(appointmentDate).toLocaleDateString('en-US', { 
    weekday: 'long', 
    year: 'numeric', 
    month: 'long', 
    day: 'numeric' 
  });
  
  const content = `
    <div class="email-body">
      <h2>📅 Referral Appointment Scheduled</h2>
      <p>Dear ${patientName},</p>
      <p>Great news! Your referral appointment with the specialist has been successfully scheduled.</p>
      
      <div class="info-box">
        <p><strong>Specialist:</strong> Dr. ${doctorName}</p>
        <p><strong>Specialty:</strong> ${specialty}</p>
        <p><strong>Date:</strong> ${formattedDate}</p>
        <p><strong>Time:</strong> ${appointmentTime}</p>
        ${clinicAddress ? `<p><strong>Location:</strong> ${clinicAddress}</p>` : ''}
      </div>
      
      <p><strong>What to bring:</strong></p>
      <ul>
        <li>Your referral letter (if provided)</li>
        <li>Previous medical records related to this consultation</li>
        <li>List of current medications</li>
        <li>Insurance information</li>
      </ul>
      
      <center>
        <a href="${actionUrl}" class="button">View Appointment Details</a>
      </center>
      
      <div class="divider"></div>
      <p style="font-size: 13px; color: #666;">
        If you have any questions before your appointment, feel free to message the specialist through the app.
      </p>
    </div>
  `;
  
  return getBaseTemplate(content);
}

export default { getReferralScheduledTemplate };
