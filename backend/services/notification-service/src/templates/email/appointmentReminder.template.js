import { getBaseTemplate } from './base.template.js';

export function getAppointmentReminderTemplate(data) {
  const { 
    patientName, 
    doctorName, 
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
      <h2>⏰ Appointment Reminder</h2>
      <p>Dear ${patientName},</p>
      <p>This is a friendly reminder about your upcoming appointment:</p>
      
      <div class="info-box">
        <p><strong>Doctor:</strong> Dr. ${doctorName}</p>
        <p><strong>Date:</strong> ${formattedDate}</p>
        <p><strong>Time:</strong> ${appointmentTime}</p>
        <p><strong>Location:</strong> ${clinicAddress || 'Please check your appointment details'}</p>
      </div>
      
      <p><strong>Before your appointment:</strong></p>
      <ul>
        <li>Review your current symptoms or concerns</li>
        <li>List any questions you want to ask your doctor</li>
        <li>Gather your medical records if needed</li>
      </ul>
      
      <p>We look forward to seeing you!</p>
      
      <center>
        <a href="${actionUrl}" class="button">View Appointment Details</a>
      </center>
    </div>
  `;
  
  return getBaseTemplate(content);
}

export default { getAppointmentReminderTemplate };
