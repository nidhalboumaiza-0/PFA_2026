import { getBaseTemplate } from './base.template.js';

export function getNewMessageTemplate(data) {
  const { 
    recipientName, 
    senderName, 
    messagePreview, 
    actionUrl 
  } = data;
  
  const content = `
    <div class="email-body">
      <h2>💬 New Message</h2>
      <p>Dear ${recipientName},</p>
      <p>You have received a new message from <strong>${senderName}</strong>:</p>
      
      <div class="info-box">
        <p style="font-style: italic; color: #555;">
          "${messagePreview}..."
        </p>
      </div>
      
      <p>Please log in to your account to view the full message and respond.</p>
      
      <center>
        <a href="${actionUrl}" class="button">View Message</a>
      </center>
      
      <div class="divider"></div>
      <p style="font-size: 13px; color: #666;">
        <strong>Privacy Notice:</strong> This message contains confidential medical information. Please ensure you're viewing this in a secure environment.
      </p>
    </div>
  `;
  
  return getBaseTemplate(content);
}

export default { getNewMessageTemplate };
