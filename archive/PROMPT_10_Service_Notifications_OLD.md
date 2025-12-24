# PROMPT 10: Service Notifications

## Objective
Build the notification service using OneSignal for push notifications and Nodemailer for emails, consuming Kafka events from all microservices.

## Requirements

### 1. Database Schema

#### Notification Model
```javascript
{
  userId: ObjectId (required, indexed),
  userType: String (enum: ['patient', 'doctor', 'admin'], required),
  
  // Notification Content
  title: String (required),
  body: String (required),
  type: String (enum: [
    'appointment_confirmed',
    'appointment_rejected',
    'appointment_reminder',
    'appointment_cancelled',
    'new_message',
    'referral_received',
    'referral_scheduled',
    'consultation_created',
    'prescription_created',
    'document_uploaded',
    'system_alert'
  ], required),
  
  // Related Resource
  relatedResource: {
    resourceType: String, // 'appointment', 'message', 'referral', etc.
    resourceId: ObjectId
  },
  
  // Delivery Channels
  channels: {
    push: {
      enabled: Boolean (default: true),
      sent: Boolean (default: false),
      sentAt: Date,
      oneSignalId: String,
      error: String
    },
    email: {
      enabled: Boolean (default: true),
      sent: Boolean (default: false),
      sentAt: Date,
      error: String
    },
    inApp: {
      enabled: Boolean (default: true),
      delivered: Boolean (default: true)
    }
  },
  
  // Status
  isRead: Boolean (default: false),
  readAt: Date,
  
  // Priority
  priority: String (enum: ['low', 'medium', 'high', 'urgent'], default: 'medium'),
  
  // Actions (deep links)
  actionUrl: String, // Frontend route
  actionData: Object, // Additional data for action
  
  // Scheduling
  scheduledFor: Date, // If notification should be sent later
  
  createdAt: Date,
  updatedAt: Date
}

// Indexes
notificationSchema.index({ userId: 1, createdAt: -1 });
notificationSchema.index({ userId: 1, isRead: 1 });
notificationSchema.index({ type: 1, createdAt: -1 });
notificationSchema.index({ scheduledFor: 1 });
```

#### NotificationPreference Model
```javascript
{
  userId: ObjectId (required, unique, indexed),
  
  preferences: {
    appointmentConfirmed: {
      push: Boolean (default: true),
      email: Boolean (default: true),
      inApp: Boolean (default: true)
    },
    appointmentReminder: {
      push: Boolean (default: true),
      email: Boolean (default: true),
      inApp: Boolean (default: true)
    },
    newMessage: {
      push: Boolean (default: true),
      email: Boolean (default: false),
      inApp: Boolean (default: true)
    },
    referral: {
      push: Boolean (default: true),
      email: Boolean (default: true),
      inApp: Boolean (default: true)
    },
    prescription: {
      push: Boolean (default: true),
      email: Boolean (default: true),
      inApp: Boolean (default: true)
    },
    systemAlert: {
      push: Boolean (default: true),
      email: Boolean (default: true),
      inApp: Boolean (default: true)
    }
  },
  
  // Quiet Hours
  quietHours: {
    enabled: Boolean (default: false),
    startTime: String, // "22:00"
    endTime: String // "08:00"
  },
  
  createdAt: Date,
  updatedAt: Date
}
```

### 2. OneSignal Integration

#### Setup Configuration
```javascript
const OneSignal = require('onesignal-node');

const client = new OneSignal.Client({
  userAuthKey: process.env.ONESIGNAL_USER_AUTH_KEY,
  app: {
    appAuthKey: process.env.ONESIGNAL_REST_API_KEY,
    appId: process.env.ONESIGNAL_APP_ID
  }
});
```

#### User Device Registration
**Endpoint:** `POST /api/v1/notifications/register-device`

**Headers:**
```
Authorization: Bearer {token}
```

**Request Body:**
```json
{
  "deviceType": "mobile", // or "web"
  "oneSignalPlayerId": "player_id_from_onesignal",
  "platform": "android" // or "ios", "web"
}
```

**Process:**
1. Authenticate user
2. Save OneSignal player ID to user profile
3. Link user to OneSignal
4. Return success

#### Send Push Notification Helper
```javascript
async function sendPushNotification(userId, notification) {
  try {
    // Get user's OneSignal player IDs
    const playerIds = await getUserPlayerIds(userId);
    
    if (playerIds.length === 0) {
      return { sent: false, error: 'No devices registered' };
    }
    
    const notificationObj = {
      contents: {
        en: notification.body
      },
      headings: {
        en: notification.title
      },
      data: {
        type: notification.type,
        resourceId: notification.relatedResource?.resourceId,
        actionUrl: notification.actionUrl
      },
      include_player_ids: playerIds,
      priority: notification.priority === 'urgent' ? 10 : 5,
      android_channel_id: notification.priority === 'urgent' 
        ? 'urgent' 
        : 'default'
    };
    
    const response = await client.createNotification(notificationObj);
    
    return {
      sent: true,
      oneSignalId: response.body.id,
      sentAt: new Date()
    };
  } catch (error) {
    console.error('Push notification error:', error);
    return {
      sent: false,
      error: error.message
    };
  }
}
```

### 3. Email Notification Templates

#### Nodemailer Helper
```javascript
async function sendEmailNotification(userId, notification) {
  try {
    const user = await getUserById(userId);
    
    if (!user.email) {
      return { sent: false, error: 'No email address' };
    }
    
    const emailTemplate = getEmailTemplate(notification.type, notification);
    
    await transporter.sendMail({
      from: process.env.EMAIL_FROM,
      to: user.email,
      subject: notification.title,
      html: emailTemplate
    });
    
    return { sent: true, sentAt: new Date() };
  } catch (error) {
    return { sent: false, error: error.message };
  }
}
```

#### Email Templates

**Appointment Confirmed:**
```html
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background-color: #4CAF50; color: white; padding: 20px; }
    .content { padding: 20px; background-color: #f9f9f9; }
    .button { background-color: #4CAF50; color: white; padding: 10px 20px; 
              text-decoration: none; display: inline-block; margin-top: 10px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h2>Appointment Confirmed</h2>
    </div>
    <div class="content">
      <p>Dear {{patientName}},</p>
      <p>Your appointment has been confirmed:</p>
      <ul>
        <li><strong>Doctor:</strong> {{doctorName}}</li>
        <li><strong>Date:</strong> {{appointmentDate}}</li>
        <li><strong>Time:</strong> {{appointmentTime}}</li>
        <li><strong>Location:</strong> {{clinicAddress}}</li>
      </ul>
      <a href="{{actionUrl}}" class="button">View Appointment</a>
    </div>
  </div>
</body>
</html>
```

**Similar templates for:**
- Appointment Reminder
- Appointment Cancelled
- New Message
- Referral Received
- Prescription Created
- etc.

### 4. Kafka Event Consumers

#### Setup Kafka Consumer
```javascript
const kafka = require('kafkajs');

const consumer = kafka.consumer({ groupId: 'notification-service' });

await consumer.connect();
await consumer.subscribe({ 
  topics: [
    'appointment.confirmed',
    'appointment.rejected',
    'appointment.cancelled',
    'message.sent',
    'referral.created',
    'referral.scheduled',
    'consultation.created',
    'prescription.created',
    'document.uploaded'
  ]
});

await consumer.run({
  eachMessage: async ({ topic, message }) => {
    const event = JSON.parse(message.value.toString());
    await handleEvent(topic, event);
  }
});
```

#### Event Handlers

**Appointment Confirmed:**
```javascript
async function handleAppointmentConfirmed(event) {
  const { appointmentId, patientId, doctorId } = event;
  
  const appointment = await getAppointmentById(appointmentId);
  const doctor = await getDoctorById(doctorId);
  
  // Notify Patient
  await createNotification({
    userId: patientId,
    userType: 'patient',
    title: 'Appointment Confirmed',
    body: `Your appointment with ${doctor.name} on ${appointment.date} has been confirmed.`,
    type: 'appointment_confirmed',
    relatedResource: {
      resourceType: 'appointment',
      resourceId: appointmentId
    },
    actionUrl: `/appointments/${appointmentId}`,
    priority: 'high'
  });
}
```

**Appointment Reminder (24 hours before):**
```javascript
async function scheduleAppointmentReminder(appointmentId) {
  const appointment = await getAppointmentById(appointmentId);
  
  // Calculate reminder time (24 hours before)
  const reminderTime = new Date(appointment.appointmentDate);
  reminderTime.setHours(reminderTime.getHours() - 24);
  
  // Create scheduled notification
  await createNotification({
    userId: appointment.patientId,
    userType: 'patient',
    title: 'Appointment Reminder',
    body: `Reminder: You have an appointment with ${doctor.name} tomorrow at ${appointment.time}.`,
    type: 'appointment_reminder',
    relatedResource: {
      resourceType: 'appointment',
      resourceId: appointmentId
    },
    scheduledFor: reminderTime,
    priority: 'high'
  });
}
```

**New Message:**
```javascript
async function handleNewMessage(event) {
  const { messageId, receiverId, senderId, content } = event;
  
  const sender = await getUserById(senderId);
  
  // Only notify if receiver is offline
  const isOnline = await isUserOnline(receiverId);
  
  if (!isOnline) {
    await createNotification({
      userId: receiverId,
      userType: event.receiverType,
      title: `New message from ${sender.name}`,
      body: content.substring(0, 100), // First 100 chars
      type: 'new_message',
      relatedResource: {
        resourceType: 'message',
        resourceId: messageId
      },
      actionUrl: `/messages/${event.conversationId}`,
      priority: 'medium'
    });
  }
}
```

**Referral Received:**
```javascript
async function handleReferralReceived(event) {
  const { referralId, targetDoctorId, referringDoctorId, patientId } = event;
  
  const referringDoctor = await getDoctorById(referringDoctorId);
  const patient = await getPatientById(patientId);
  
  await createNotification({
    userId: targetDoctorId,
    userType: 'doctor',
    title: 'New Referral Received',
    body: `Dr. ${referringDoctor.name} referred patient ${patient.name} to you.`,
    type: 'referral_received',
    relatedResource: {
      resourceType: 'referral',
      resourceId: referralId
    },
    actionUrl: `/referrals/${referralId}`,
    priority: event.urgency === 'urgent' ? 'urgent' : 'high'
  });
}
```

### 5. Core Notification Functions

#### Create and Send Notification
```javascript
async function createNotification(notificationData) {
  // Get user preferences
  const preferences = await getNotificationPreferences(notificationData.userId);
  
  // Check quiet hours
  if (isQuietHours(preferences)) {
    notificationData.priority = 'low';
    notificationData.channels.push = false; // Don't send push during quiet hours
  }
  
  // Create notification in database
  const notification = await Notification.create(notificationData);
  
  // Send via enabled channels based on preferences
  const typePrefs = getPreferencesForType(preferences, notificationData.type);
  
  const results = {};
  
  // Send Push Notification
  if (typePrefs.push && notificationData.channels.push.enabled) {
    const pushResult = await sendPushNotification(
      notificationData.userId, 
      notification
    );
    notification.channels.push = { ...notification.channels.push, ...pushResult };
  }
  
  // Send Email
  if (typePrefs.email && notificationData.channels.email.enabled) {
    const emailResult = await sendEmailNotification(
      notificationData.userId, 
      notification
    );
    notification.channels.email = { ...notification.channels.email, ...emailResult };
  }
  
  await notification.save();
  
  // Emit real-time notification via Socket.IO
  if (typePrefs.inApp) {
    io.to(notificationData.userId.toString()).emit('new_notification', {
      notificationId: notification._id,
      title: notification.title,
      body: notification.body,
      type: notification.type,
      actionUrl: notification.actionUrl,
      priority: notification.priority
    });
  }
  
  return notification;
}
```

### 6. API Endpoints

#### A. Get User Notifications
**Endpoint:** `GET /api/v1/notifications`

**Headers:**
```
Authorization: Bearer {token}
```

**Query Parameters:**
```
?isRead=false
&type=appointment_confirmed
&page=1
&limit=20
```

**Response:**
```json
{
  "success": true,
  "data": {
    "notifications": [
      {
        "id": "...",
        "title": "Appointment Confirmed",
        "body": "Your appointment with Dr. Sarah Smith...",
        "type": "appointment_confirmed",
        "isRead": false,
        "priority": "high",
        "actionUrl": "/appointments/123",
        "createdAt": "2025-11-10T14:00:00Z"
      }
    ],
    "unreadCount": 5,
    "pagination": {...}
  }
}
```

#### B. Mark Notification as Read
**Endpoint:** `PUT /api/v1/notifications/:notificationId/read`

**Headers:**
```
Authorization: Bearer {token}
```

#### C. Mark All as Read
**Endpoint:** `PUT /api/v1/notifications/mark-all-read`

**Headers:**
```
Authorization: Bearer {token}
```

#### D. Get Unread Count
**Endpoint:** `GET /api/v1/notifications/unread-count`

**Response:**
```json
{
  "success": true,
  "data": {
    "unreadCount": 5
  }
}
```

#### E. Get Notification Preferences
**Endpoint:** `GET /api/v1/notifications/preferences`

**Headers:**
```
Authorization: Bearer {token}
```

#### F. Update Notification Preferences
**Endpoint:** `PUT /api/v1/notifications/preferences`

**Headers:**
```
Authorization: Bearer {token}
```

**Request Body:**
```json
{
  "preferences": {
    "appointmentConfirmed": {
      "push": true,
      "email": true,
      "inApp": true
    },
    "newMessage": {
      "push": true,
      "email": false,
      "inApp": true
    }
  },
  "quietHours": {
    "enabled": true,
    "startTime": "22:00",
    "endTime": "08:00"
  }
}
```

#### G. Register Device
**Endpoint:** `POST /api/v1/notifications/register-device`

(See OneSignal Integration section above)

#### H. Test Notification (Admin/Dev)
**Endpoint:** `POST /api/v1/notifications/test`

**Headers:**
```
Authorization: Bearer {adminToken}
```

**Request Body:**
```json
{
  "userId": "userId123",
  "title": "Test Notification",
  "body": "This is a test",
  "type": "system_alert"
}
```

### 7. Background Jobs

#### Scheduled Notifications Processor
```javascript
// Runs every minute
async function processScheduledNotifications() {
  const now = new Date();
  
  const scheduled = await Notification.find({
    scheduledFor: { $lte: now },
    'channels.push.sent': false
  });
  
  for (const notification of scheduled) {
    await sendNotificationChannels(notification);
  }
}
```

#### Appointment Reminder Scheduler
```javascript
// Runs daily
async function scheduleAppointmentReminders() {
  const tomorrow = new Date();
  tomorrow.setDate(tomorrow.getDate() + 1);
  
  const appointments = await Appointment.find({
    appointmentDate: {
      $gte: tomorrow,
      $lt: new Date(tomorrow.getTime() + 24*60*60*1000)
    },
    status: 'confirmed',
    reminderSent: false
  });
  
  for (const appointment of appointments) {
    await scheduleAppointmentReminder(appointment._id);
  }
}
```

### 8. Notification Types & Templates

Create comprehensive templates for:
1. ✅ Appointment Confirmed
2. ✅ Appointment Rejected
3. ✅ Appointment Reminder (24h, 1h before)
4. ✅ Appointment Cancelled
5. ✅ New Message
6. ✅ Referral Received
7. ✅ Referral Scheduled
8. ✅ Referral Completed
9. ✅ Consultation Created
10. ✅ Prescription Created
11. ✅ Document Uploaded
12. ✅ System Alert

## API Endpoints Summary
```
GET    /api/v1/notifications
GET    /api/v1/notifications/unread-count
PUT    /api/v1/notifications/:notificationId/read
PUT    /api/v1/notifications/mark-all-read
GET    /api/v1/notifications/preferences
PUT    /api/v1/notifications/preferences
POST   /api/v1/notifications/register-device
POST   /api/v1/notifications/test (admin)
```

## Deliverables
1. ✅ Notification and Preference models
2. ✅ OneSignal integration
3. ✅ Nodemailer email templates
4. ✅ Kafka event consumers
5. ✅ Event handlers for all notification types
6. ✅ Push notification system
7. ✅ Email notification system
8. ✅ In-app notification (Socket.IO)
9. ✅ User preferences management
10. ✅ Scheduled notifications
11. ✅ Quiet hours support
12. ✅ Background jobs

## Testing Checklist
- [ ] Push notification sent successfully
- [ ] Email notification sent
- [ ] In-app notification delivered
- [ ] Kafka events trigger notifications
- [ ] User preferences respected
- [ ] Quiet hours work correctly
- [ ] Scheduled reminders sent
- [ ] Unread count accurate
- [ ] Mark as read works
- [ ] Device registration works
- [ ] All notification types working

---

**Next Step:** After this prompt is complete, proceed to PROMPT 11 (Service Audit)
