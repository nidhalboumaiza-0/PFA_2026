import { getBaseTemplate } from './base.template.js';

export function getAppointmentCancelledTemplate(data) {
  const { 
    patientName, 
    doctorName, 
    appointmentDate, 
    cancellationReason, 
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
      <h2>❌ Appointment Cancelled</h2>
      <p>Dear ${patientName},</p>
      <p>Your appointment with <strong>Dr. ${doctorName}</strong> scheduled for <strong>${formattedDate}</strong> has been cancelled.</p>
      
      ${cancellationReason ? `
        <div class="info-box">
          <p><strong>Cancellation Reason:</strong></p>
          <p>${cancellationReason}</p>
        </div>
      ` : ''}
      
      <p>We apologize for any inconvenience. If you would like to reschedule or book a new appointment, please use the button below.</p>
      
      <center>
        <a href="${actionUrl}" class="button">Book New Appointment</a>
      </center>
      
      <div class="divider"></div>
      <p style="font-size: 13px; color: #666;">
        If you have any questions, please contact us through the app or call the clinic directly.
      </p>
    </div>
  `;
  
  return getBaseTemplate(content);
}

export default { getAppointmentCancelledTemplate };
