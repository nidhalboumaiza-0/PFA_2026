# Notification Service

Multi-channel notification service for E-Santé platform with push notifications (OneSignal), email notifications (Nodemailer), in-app notifications (Socket.IO), and Kafka event consumption.

## Features

- ✅ **Push Notifications**: OneSignal integration for mobile/web push notifications
- ✅ **Email Notifications**: Nodemailer with HTML templates for all notification types
- ✅ **In-App Notifications**: Real-time Socket.IO notifications
- ✅ **Kafka Event Consumption**: Auto-generate notifications from 10 service events
- ✅ **User Preferences**: Per-channel preferences for 7 notification types
- ✅ **Quiet Hours**: Disable push notifications during user-defined hours (email still sent)
- ✅ **Device Management**: Register/unregister OneSignal player IDs
- ✅ **Scheduled Notifications**: Appointment reminders 24 hours before
- ✅ **Background Jobs**: Cron job for processing scheduled notifications
- ✅ **Priority Levels**: low, medium, high, urgent
- ✅ **Deep Linking**: Action URLs for frontend navigation
- ✅ **HTML Email Templates**: 9 professional templates with responsive design

## Technology Stack

- **Runtime**: Node.js with ES6 modules
- **Framework**: Express.js
- **Database**: MongoDB with Mongoose
- **Push Notifications**: OneSignal (onesignal-node ^3.4.0)
- **Email**: Nodemailer ^6.9.7
- **Real-time**: Socket.IO ^4.6.1
- **Event Streaming**: KafkaJS ^2.2.4
- **Scheduling**: node-cron ^3.0.2
- **Validation**: Joi
- **Authentication**: JWT

## Port

- **3007**

## Environment Variables

```env
# Server
PORT=3007
NODE_ENV=development

# MongoDB
MONGODB_URI=mongodb://localhost:27017/esante-notifications

# JWT
JWT_SECRET=your_jwt_secret_key_here

# Kafka
KAFKA_BROKER=localhost:9092
KAFKA_CLIENT_ID=notification-service
KAFKA_GROUP_ID=notification-service-group

# OneSignal
ONESIGNAL_APP_ID=your_onesignal_app_id
ONESIGNAL_REST_API_KEY=your_onesignal_rest_api_key
ONESIGNAL_USER_AUTH_KEY=your_onesignal_user_auth_key

# Email Configuration (Nodemailer)
EMAIL_SERVICE=gmail
EMAIL_USER=your-email@gmail.com
EMAIL_PASSWORD=your_app_password
EMAIL_FROM="E-Santé <noreply@esante.com>"

# Service URLs
USER_SERVICE_URL=http://localhost:3002
RDV_SERVICE_URL=http://localhost:3003
MESSAGING_SERVICE_URL=http://localhost:3006

# Frontend
FRONTEND_URL=http://localhost:3000

# Notification Settings
DEFAULT_NOTIFICATION_LIMIT=20
MAX_NOTIFICATION_LIMIT=100
SCHEDULED_NOTIFICATION_INTERVAL=* * * * *
```

## Email Setup (Nodemailer)

### Using Gmail

1. **Enable 2-Factor Authentication** on your Gmail account

2. **Generate App Password**:
   - Go to Google Account Settings
   - Security → 2-Step Verification → App passwords
   - Select "Mail" and "Other (Custom name)"
   - Copy the generated 16-character password

3. **Configure Environment Variables**:
   ```env
   EMAIL_SERVICE=gmail
   EMAIL_USER=your-email@gmail.com
   EMAIL_PASSWORD=your_16_char_app_password
   EMAIL_FROM="E-Santé <noreply@esante.com>"
   ```

### Using Custom SMTP

```env
EMAIL_HOST=smtp.your-provider.com
EMAIL_PORT=587
EMAIL_SECURE=false
EMAIL_USER=your-email@domain.com
EMAIL_PASSWORD=your_password
EMAIL_FROM="E-Santé <noreply@esante.com>"
```

### Email Templates

The service includes 9 professional HTML email templates:

1. **Appointment Confirmed** - Confirmation with clinic details
2. **Appointment Reminder** - 24-hour reminder
3. **Appointment Cancelled** - Cancellation notification
4. **New Message** - Message preview with sender info
5. **Referral Received** - Doctor receives referral (with urgency)
6. **Referral Scheduled** - Patient notified of specialist appointment
7. **Prescription Created** - Medication list and instructions
8. **Document Uploaded** - New medical document notification
9. **Consultation Created** - Consultation notes added

All templates are:
- ✅ Responsive (mobile-friendly)
- ✅ Professionally styled with gradient headers
- ✅ Include action buttons for deep linking
- ✅ Have consistent branding
- ✅ Include privacy/unsubscribe footer

### Quiet Hours

Users can configure quiet hours (default: 22:00 - 07:00):
- **Push notifications** are disabled during quiet hours
- **Email notifications** are still sent (important medical info)
- **In-app notifications** continue to work

Configure via preferences:
```json
{
  "quietHours": {
    "enabled": true,
    "startTime": "22:00",
    "endTime": "07:00"
  }
}
```

## OneSignal Setup

### 1. Create OneSignal Account
1. Go to [OneSignal.com](https://onesignal.com)
2. Sign up for free account
3. Create new app

### 2. Get API Credentials
Navigate to **Settings > Keys & IDs**:
- **App ID**: Copy to `ONESIGNAL_APP_ID`
- **REST API Key**: Copy to `ONESIGNAL_REST_API_KEY`
- **User Auth Key**: Copy to `ONESIGNAL_USER_AUTH_KEY`

### 3. Configure Mobile App
For React Native:
```bash
npm install react-native-onesignal
```

Initialize OneSignal:
```javascript
import OneSignal from 'react-native-onesignal';

OneSignal.setAppId('your_app_id');
OneSignal.setNotificationWillShowInForegroundHandler(notificationReceivedEvent => {
  // Handle notification
});
```

### 4. Register Device
After OneSignal initialization:
```javascript
// Get OneSignal player ID
OneSignal.getDeviceState((deviceState) => {
  const playerId = deviceState.userId;
  
  // Register with backend
  fetch('http://localhost:3007/api/v1/notifications/register-device', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      oneSignalPlayerId: playerId,
      deviceType: 'mobile',
      platform: 'ios' // or 'android'
    })
  });
});
```

## API Endpoints

### 1. Get Notifications
```http
GET /api/v1/notifications
Authorization: Bearer <token>
Query Parameters:
  - isRead (boolean, optional): Filter by read status
  - type (string, optional): Filter by notification type
  - page (number, default: 1)
  - limit (number, default: 20, max: 100)

Response:
{
  "success": true,
  "data": {
    "notifications": [
      {
        "id": "60d5ec49f1b2c72b8c8e4f1a",
        "userId": "60d5ec49f1b2c72b8c8e4f1b",
        "userType": "patient",
        "title": "Rendez-vous confirmé",
        "body": "Votre rendez-vous avec Dr. Martin a été confirmé...",
        "type": "appointment_confirmed",
        "relatedResource": {
          "resourceType": "appointment",
          "resourceId": "60d5ec49f1b2c72b8c8e4f1c"
        },
        "channels": {
          "push": { "enabled": true, "sent": true, "sentAt": "2024-01-15T10:30:00Z" },
          "email": { "enabled": true, "sent": false },
          "inApp": { "enabled": true, "delivered": true }
        },
        "isRead": false,
        "priority": "high",
        "actionUrl": "/appointments/60d5ec49f1b2c72b8c8e4f1c",
        "createdAt": "2024-01-15T10:30:00Z"
      }
    ],
    "unreadCount": 5,
    "pagination": {
      "currentPage": 1,
      "totalPages": 3,
      "totalItems": 45,
      "itemsPerPage": 20,
      "hasNextPage": true,
      "hasPrevPage": false
    }
  }
}
```

### 2. Get Unread Count
```http
GET /api/v1/notifications/unread-count
Authorization: Bearer <token>

Response:
{
  "success": true,
  "data": {
    "unreadCount": 5
  }
}
```

### 3. Mark as Read
```http
PUT /api/v1/notifications/:id/read
Authorization: Bearer <token>

Response:
{
  "success": true,
  "message": "Notification marked as read",
  "data": { ... }
}
```

### 4. Mark All as Read
```http
PUT /api/v1/notifications/mark-all-read
Authorization: Bearer <token>

Response:
{
  "success": true,
  "message": "5 notification(s) marked as read",
  "data": { "count": 5 }
}
```

### 5. Get Preferences
```http
GET /api/v1/notifications/preferences
Authorization: Bearer <token>

Response:
{
  "success": true,
  "data": {
    "userId": "60d5ec49f1b2c72b8c8e4f1b",
    "preferences": {
      "appointmentConfirmed": { "push": true, "email": true, "inApp": true },
      "appointmentReminder": { "push": true, "email": true, "inApp": true },
      "appointmentCancelled": { "push": true, "email": true, "inApp": true },
      "newMessage": { "push": true, "email": false, "inApp": true },
      "referral": { "push": true, "email": true, "inApp": true },
      "prescription": { "push": true, "email": true, "inApp": true },
      "systemAlert": { "push": true, "email": true, "inApp": true }
    },
    "devices": [
      {
        "oneSignalPlayerId": "abc123-def456",
        "deviceType": "mobile",
        "platform": "ios",
        "registeredAt": "2024-01-15T10:00:00Z"
      }
    ]
  }
}
```

### 6. Update Preferences
```http
PUT /api/v1/notifications/preferences
Authorization: Bearer <token>
Content-Type: application/json

Body:
{
  "preferences": {
    "appointmentConfirmed": { "push": true, "email": true, "inApp": true },
    "newMessage": { "push": false, "email": false, "inApp": true }
  }
}

Response:
{
  "success": true,
  "message": "Notification preferences updated successfully",
  "data": { ... }
}
```

### 7. Register Device
```http
POST /api/v1/notifications/register-device
Authorization: Bearer <token>
Content-Type: application/json

Body:
{
  "oneSignalPlayerId": "abc123-def456",
  "deviceType": "mobile",
  "platform": "ios"
}

Response:
{
  "success": true,
  "message": "Device registered successfully",
  "data": { "added": true }
}
```

### 8. Unregister Device
```http
DELETE /api/v1/notifications/devices/:playerId
Authorization: Bearer <token>

Response:
{
  "success": true,
  "message": "Device unregistered successfully"
}
```

## Notification Types

| Type | Description | Default Priority | Channels |
|------|-------------|------------------|----------|
| `appointment_confirmed` | Appointment confirmed by doctor | high | push, email, inApp |
| `appointment_rejected` | Appointment request rejected | medium | push, email, inApp |
| `appointment_reminder` | 24h appointment reminder | high | push, email, inApp |
| `appointment_cancelled` | Appointment cancelled | high | push, email, inApp |
| `new_message` | New message received (offline only) | medium | push, inApp |
| `referral_received` | Doctor received referral | high | push, email, inApp |
| `referral_scheduled` | Referral appointment scheduled | high | push, email, inApp |
| `consultation_created` | New consultation record | medium | push, email, inApp |
| `prescription_created` | New prescription | medium | push, email, inApp |
| `document_uploaded` | Medical document uploaded | medium | push, email, inApp |
| `system_alert` | System notification | urgent | push, email, inApp |

## Kafka Topics Consumed

| Topic | Description | Event Data |
|-------|-------------|------------|
| `rdv.appointment.confirmed` | Appointment confirmed | appointmentId, patientId, doctorId, scheduledDate |
| `rdv.appointment.rejected` | Appointment rejected | appointmentId, patientId, doctorId, reason |
| `rdv.appointment.cancelled` | Appointment cancelled | appointmentId, patientId, doctorId, cancelledBy, reason |
| `rdv.appointment.reminder` | Schedule reminder (24h before) | appointmentId, patientId, doctorId, scheduledDate |
| `messaging.message.sent` | New message (offline only) | conversationId, senderId, receiverId, senderName, isReceiverOnline |
| `referral.referral.created` | New referral | referralId, referringDoctorId, targetDoctorId, patientId, specialty |
| `referral.referral.scheduled` | Referral appointment scheduled | referralId, patientId, targetDoctorId, appointmentId, scheduledDate |

## Socket.IO Events

### Client Connection
```javascript
import io from 'socket.io-client';

const socket = io('http://localhost:3007', {
  auth: {
    token: 'your_jwt_token'
  }
});

// Listen for notifications
socket.on('new_notification', (notification) => {
  console.log('New notification:', notification);
  // Show notification in UI
  showNotification(notification);
});

// Handle connection errors
socket.on('connect_error', (error) => {
  console.error('Connection error:', error.message);
});
```

### Emitted Events
- **new_notification**: Sent when user receives notification while online

## Installation

```bash
# Navigate to notification service
cd backend/services/notification-service

# Install dependencies
npm install

# Set up environment variables
cp .env.example .env
# Edit .env with your OneSignal credentials

# Start service (development)
npm run dev

# Start service (production)
npm start
```

## Dependencies

```json
{
  "express": "^4.18.2",
  "mongoose": "^7.5.0",
  "socket.io": "^4.6.1",
  "kafkajs": "^2.2.4",
  "onesignal-node": "^3.4.0",
  "node-cron": "^3.0.2",
  "joi": "^17.9.2",
  "axios": "^1.4.0",
  "jsonwebtoken": "^9.0.1",
  "dotenv": "^16.3.1",
  "helmet": "^7.0.0",
  "cors": "^2.8.5"
}
```

## Testing

### 1. Test Device Registration
```bash
curl -X POST http://localhost:3007/api/v1/notifications/register-device \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "oneSignalPlayerId": "test-player-id",
    "deviceType": "mobile",
    "platform": "ios"
  }'
```

### 2. Test Kafka Event Consumption
Trigger appointment confirmation from RDV Service - notification should be auto-created.

### 3. Test Socket.IO
Connect Socket.IO client and verify real-time notification delivery.

### 4. Test Scheduled Notifications
Create appointment reminder event - notification should be sent 24h before appointment.

### 5. Test Preferences
Update preferences to disable push - verify push notifications not sent.

## Architecture

```
notification-service/
├── src/
│   ├── models/
│   │   ├── Notification.js           # Notification schema with multi-channel tracking
│   │   └── NotificationPreference.js  # User preferences and devices
│   ├── controllers/
│   │   └── notificationController.js  # 8 REST endpoint handlers
│   ├── services/
│   │   ├── notificationService.js     # Core notification creation logic
│   │   └── pushNotificationService.js # OneSignal integration
│   ├── kafka/
│   │   └── notificationConsumer.js    # Consume 7 Kafka topics + event handlers
│   ├── socket/
│   │   └── socket.js                  # Socket.IO setup for in-app notifications
│   ├── jobs/
│   │   └── scheduledNotificationJob.js # Cron job for scheduled notifications
│   ├── validators/
│   │   └── notificationValidator.js   # Joi validation schemas
│   ├── routes/
│   │   └── notificationRoutes.js      # API routes
│   ├── config/
│   │   └── onesignal.js               # OneSignal client configuration
│   ├── utils/
│   │   └── helpers.js                 # Helper functions (getUserInfo, etc.)
│   └── server.js                      # Main server with MongoDB + Kafka + Socket.IO
├── .env
├── package.json
└── README.md
```

## Data Flow

### 1. Kafka Event → Notification
```
RDV Service publishes event → Kafka
  ↓
Notification Service consumes event
  ↓
Extract event data (appointmentId, userId, etc.)
  ↓
Fetch related data (doctor name, patient name, etc.)
  ↓
createNotification() with formatted title/body
  ↓
Check user preferences (push/email/inApp enabled?)
  ↓
Send push via OneSignal (if enabled)
Send in-app via Socket.IO (if enabled and online)
Email channel prepared (PROMPT 10B)
  ↓
Save notification with delivery status
```

### 2. Scheduled Notification Flow
```
Appointment reminder event received
  ↓
Calculate scheduledFor = appointmentDate - 24 hours
  ↓
Create notification with scheduledFor date
  ↓
Background job runs every minute
  ↓
Find notifications where scheduledFor <= now
  ↓
Send push notifications
  ↓
Update sent status
```

## Error Handling

- Kafka connection failures: Retry with exponential backoff
- OneSignal API errors: Log error, mark push.sent = false, save error message
- Socket.IO disconnections: Store notification in DB, user gets on reconnect
- Device not registered: Return error message prompting registration
- Invalid preferences: Joi validation returns 400 error

## Security

- ✅ JWT authentication required for all endpoints
- ✅ User can only access own notifications
- ✅ Helmet.js security headers
- ✅ CORS configured for frontend domain
- ✅ Device registration validated (OneSignal player ID format)
- ✅ Socket.IO JWT authentication
- ✅ Input validation with Joi

## Performance

- **Indexes**: 4 compound indexes for fast queries
  - userId + createdAt (desc)
  - userId + isRead
  - type + createdAt (desc)
  - scheduledFor
- **Pagination**: Default 20 items, max 100
- **Background Job**: Runs every minute (configurable)
- **Kafka**: Consumer group for horizontal scaling

## Monitoring

### Health Check
```http
GET /health

Response:
{
  "success": true,
  "message": "Notification Service is healthy",
  "data": {
    "status": "healthy",
    "timestamp": "2024-01-15T10:30:00Z",
    "mongodb": "connected",
    "unreadNotifications": 42
  }
}
```

### Logs
- ✅ Kafka event consumption
- ✅ Push notification delivery
- ✅ Socket.IO connections
- ✅ Scheduled job execution
- ✅ Error logging with context

## Future Enhancements (PROMPT 10B)

- Email notification delivery (SMTP/SendGrid)
- Email templates (HTML formatted)
- Notification batching (digest emails)
- Advanced scheduling (custom intervals)
- Notification history export
- Analytics (open rate, click rate)

## Support

For issues or questions:
- Check logs: `npm run dev`
- Verify Kafka connection: Check KAFKA_BROKER
- Verify OneSignal credentials: Test in OneSignal dashboard
- Check MongoDB: `mongo esante-notifications`

## License

MIT
