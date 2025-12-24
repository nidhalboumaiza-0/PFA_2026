import { getBaseTemplate } from './base.template.js';

export function getDocumentUploadedTemplate(data) {
  const { 
    patientName, 
    uploaderName, 
    documentTitle, 
    documentType, 
    actionUrl 
  } = data;
  
  const typeLabels = {
    lab_result: 'Lab Result',
    imaging: 'Medical Imaging',
    prescription: 'Prescription',
    insurance: 'Insurance Document',
    medical_report: 'Medical Report',
    other: 'Medical Document'
  };
  
  const typeLabel = typeLabels[documentType] || 'Medical Document';
  
  const content = `
    <div class="email-body">
      <h2>📄 New Medical Document</h2>
      <p>Dear ${patientName},</p>
      <p><strong>${uploaderName}</strong> has uploaded a new medical document to your records.</p>
      
      <div class="info-box">
        <p><strong>Document Title:</strong> ${documentTitle}</p>
        <p><strong>Document Type:</strong> ${typeLabel}</p>
        <p><strong>Uploaded By:</strong> ${uploaderName}</p>
      </div>
      
      <p>The document is now available in your medical records. You can view, download, or share it with other healthcare providers as needed.</p>
      
      <center>
        <a href="${actionUrl}" class="button">View Document</a>
      </center>
      
      <div class="divider"></div>
      <p style="font-size: 13px; color: #666;">
        <strong>Privacy:</strong> Your medical documents are encrypted and securely stored. Only you and authorized healthcare providers can access them.
      </p>
    </div>
  `;
  
  return getBaseTemplate(content);
}

export default { getDocumentUploadedTemplate };
