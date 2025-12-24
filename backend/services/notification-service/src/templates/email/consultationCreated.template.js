import { getBaseTemplate } from './base.template.js';

export function getConsultationCreatedTemplate(data) {
  const { 
    patientName, 
    doctorName, 
    consultationDate, 
    diagnosis, 
    chiefComplaint,
    actionUrl 
  } = data;
  
  const formattedDate = new Date(consultationDate).toLocaleDateString('en-US', { 
    weekday: 'long', 
    year: 'numeric', 
    month: 'long', 
    day: 'numeric' 
  });
  
  const content = `
    <div class="email-body">
      <h2>📝 Consultation Record Added</h2>
      <p>Dear ${patientName},</p>
      <p><strong>Dr. ${doctorName}</strong> has completed your consultation and added the details to your medical records.</p>
      
      <div class="info-box">
        <p><strong>Consultation Date:</strong> ${formattedDate}</p>
        ${chiefComplaint ? `<p><strong>Chief Complaint:</strong> ${chiefComplaint}</p>` : ''}
        ${diagnosis ? `<p><strong>Diagnosis:</strong> ${diagnosis}</p>` : ''}
      </div>
      
      <p>You can now view the complete consultation notes, including:</p>
      <ul>
        <li>Detailed medical notes</li>
        <li>Vital signs recorded during the visit</li>
        <li>Prescribed treatments or medications</li>
        <li>Follow-up recommendations (if any)</li>
      </ul>
      
      <center>
        <a href="${actionUrl}" class="button">View Consultation Details</a>
      </center>
      
      <div class="divider"></div>
      <p style="font-size: 13px; color: #666;">
        If you have any questions about your consultation, you can message your doctor directly through the app.
      </p>
    </div>
  `;
  
  return getBaseTemplate(content);
}

export default { getConsultationCreatedTemplate };
