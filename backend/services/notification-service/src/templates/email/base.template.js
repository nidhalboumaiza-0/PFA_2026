/**
 * Base HTML Email Template
 * Provides consistent styling for all email notifications
 */

import { getConfig } from '../../../../../shared/index.js';

export function getBaseTemplate(content) {
  const frontendUrl = getConfig('FRONTEND_URL', 'http://localhost:3000');
  
  return `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <title>E-Santé Notification</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
      line-height: 1.6;
      color: #333;
      margin: 0;
      padding: 0;
      background-color: #f4f7f9;
    }
    .email-container {
      max-width: 600px;
      margin: 20px auto;
      background-color: #ffffff;
      border-radius: 8px;
      overflow: hidden;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    }
    .email-header {
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: white;
      padding: 30px 20px;
      text-align: center;
    }
    .email-header h1 {
      margin: 0;
      font-size: 28px;
      font-weight: 600;
    }
    .email-header p {
      margin: 5px 0 0 0;
      font-size: 14px;
      opacity: 0.9;
    }
    .email-body {
      padding: 30px 25px;
    }
    .email-body h2 {
      color: #667eea;
      font-size: 22px;
      margin-top: 0;
      margin-bottom: 15px;
    }
    .email-body p {
      margin: 10px 0;
      font-size: 15px;
      line-height: 1.7;
    }
    .info-box {
      background-color: #f8f9fa;
      border-left: 4px solid #667eea;
      padding: 15px 20px;
      margin: 20px 0;
      border-radius: 4px;
    }
    .info-box p {
      margin: 8px 0;
      font-size: 14px;
    }
    .info-box strong {
      color: #667eea;
      font-weight: 600;
    }
    .button {
      display: inline-block;
      background-color: #667eea;
      color: white !important;
      padding: 12px 30px;
      text-decoration: none;
      border-radius: 5px;
      margin: 20px 0;
      font-weight: 600;
      font-size: 15px;
      transition: background-color 0.3s;
    }
    .button:hover {
      background-color: #5568d3;
    }
    .email-footer {
      background-color: #f8f9fa;
      padding: 20px 25px;
      text-align: center;
      font-size: 12px;
      color: #666;
      border-top: 1px solid #e0e0e0;
    }
    .email-footer p {
      margin: 5px 0;
    }
    .email-footer a {
      color: #667eea;
      text-decoration: none;
    }
    .email-footer a:hover {
      text-decoration: underline;
    }
    .divider {
      height: 1px;
      background-color: #e0e0e0;
      margin: 20px 0;
    }
    ul {
      padding-left: 20px;
      margin: 15px 0;
    }
    ul li {
      margin: 8px 0;
      font-size: 14px;
    }
    @media only screen and (max-width: 600px) {
      .email-container {
        margin: 0;
        border-radius: 0;
      }
      .email-header {
        padding: 20px 15px;
      }
      .email-body {
        padding: 20px 15px;
      }
      .button {
        display: block;
        padding: 14px 20px;
      }
    }
  </style>
</head>
<body>
  <div class="email-container">
    <div class="email-header">
      <h1>🏥 E-Santé</h1>
      <p>Healthcare Platform</p>
    </div>
    ${content}
    <div class="email-footer">
      <p><strong>© 2025 E-Santé. All rights reserved.</strong></p>
      <p>This is an automated notification. Please do not reply to this email.</p>
      <div class="divider"></div>
      <p>
        <a href="${frontendUrl}/settings/notifications">Manage Notification Preferences</a> | 
        <a href="${frontendUrl}/support">Help & Support</a>
      </p>
    </div>
  </div>
</body>
</html>
  `;
}

export default { getBaseTemplate };
