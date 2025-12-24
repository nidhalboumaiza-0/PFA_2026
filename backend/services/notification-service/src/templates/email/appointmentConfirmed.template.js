import { getBaseTemplate } from './base.template.js';

export function getAppointmentConfirmedTemplate(data) {
  const { 
    patientName, 
    doctorName, 
    appointmentDate, 
    appointmentTime, 
    clinicName, 
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
      <h2>✅ Appointment Confirmed</h2>
      <p>Dear ${patientName},</p>
      <p>Your appointment has been successfully confirmed. We look forward to seeing you!</p>
      
      <div class="info-box">
        <p><strong>Doctor:</strong> Dr. ${doctorName}</p>
        <p><strong>Date:</strong> ${formattedDate}</p>
        <p><strong>Time:</strong> ${appointmentTime}</p>
        <p><strong>Clinic:</strong> ${clinicName || 'Main Clinic'}</p>
        <p><strong>Address:</strong> ${clinicAddress || 'Please check your appointment details'}</p>
      </div>
      
      <p><strong>Important Reminders:</strong></p>
      <ul>
        <li>Please arrive 10 minutes early for check-in</li>
        <li>Bring your insurance card and a valid ID</li>
        <li>Bring any relevant medical records or test results</li>
        <li>Prepare a list of current medications</li>
      </ul>
      
      <center>
        <a href="${actionUrl}" class="button">View Appointment Details</a>
      </center>
      
      <div class="divider"></div>
      <p style="font-size: 13px; color: #666;">
        <strong>Need to cancel or reschedule?</strong> Please do so at least 24 hours in advance through the app or by contacting the clinic directly.
      </p>
    </div>
  `;
  
  return getBaseTemplate(content);
}

export default { getAppointmentConfirmedTemplate };
