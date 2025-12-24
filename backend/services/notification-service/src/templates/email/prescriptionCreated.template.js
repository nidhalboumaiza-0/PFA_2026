import { getBaseTemplate } from './base.template.js';

export function getPrescriptionCreatedTemplate(data) {
  const { 
    patientName, 
    doctorName, 
    medicationCount, 
    medications,
    actionUrl 
  } = data;
  
  const content = `
    <div class="email-body">
      <h2>💊 New Prescription</h2>
      <p>Dear ${patientName},</p>
      <p><strong>Dr. ${doctorName}</strong> has created a new prescription for you with <strong>${medicationCount}</strong> medication${medicationCount > 1 ? 's' : ''}.</p>
      
      ${medications && medications.length > 0 ? `
        <div class="info-box">
          <p><strong>Prescribed Medications:</strong></p>
          <ul style="margin: 10px 0; padding-left: 20px;">
            ${medications.map(med => `
              <li style="margin: 8px 0;">
                <strong>${med.medicationName}</strong> - ${med.dosage}
                ${med.frequency ? `<br/><span style="font-size: 13px; color: #666;">Take ${med.frequency}</span>` : ''}
              </li>
            `).join('')}
          </ul>
        </div>
      ` : ''}
      
      <p><strong>Important reminders:</strong></p>
      <ul>
        <li>Take medications exactly as prescribed</li>
        <li>Read all instructions and warnings carefully</li>
        <li>Contact your doctor if you experience side effects</li>
        <li>Complete the full course even if you feel better</li>
      </ul>
      
      <center>
        <a href="${actionUrl}" class="button">View Full Prescription</a>
      </center>
      
      <div class="divider"></div>
      <p style="font-size: 13px; color: #666;">
        <strong>Note:</strong> You can download and print your prescription from the app to take to your pharmacy.
      </p>
    </div>
  `;
  
  return getBaseTemplate(content);
}

export default { getPrescriptionCreatedTemplate };
