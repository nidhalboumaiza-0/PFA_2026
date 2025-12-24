# Messaging Service - E-Santé Platform

Real-time messaging system using Socket.IO for patient-doctor and doctor-doctor communication with message history, typing indicators, read receipts, and file attachments.

## Features

### ✅ Real-Time Communication
- **Socket.IO Integration**: WebSocket-based bidirectional communication
- **JWT Authentication**: Secure socket connections
- **Online/Offline Status**: Real-time presence tracking
- **Typing Indicators**: Show when other user is typing
- **Read Receipts**: Message delivered and read status
- **Message Delivery**: Instant delivery to online users

### ✅ Conversation Management
- **Create/Get Conversations**: Initiate or retrieve existing conversations
- **Participant Validation**: Verify users can message each other
- **Conversation Types**: Patient-doctor and doctor-doctor messaging
- **Unread Count**: Track unread messages per conversation
- **Last Message**: Quick preview in conversation list

### ✅ Message Features
- **Text Messages**: Standard text communication (up to 5000 characters)
- **File Attachments**: Send images and documents (up to 10MB)
- **Message History**: Paginated message retrieval
- **Message Search**: Full-text search across messages
- **Soft Delete**: Mark messages as deleted
- **Message Metadata**: Store additional context (e.g., referral links)

### ✅ Security & Access Control
- **Authentication Required**: All endpoints and socket events
- **Participant Verification**: Only conversation participants can interact
- **File Validation**: Type and size limits enforced
- **AWS S3 Storage**: Secure file storage

### ✅ Integration
- **Kafka Events**: Message sent/delivered/read events
- **User Service**: Fetch user profiles and validate users
- **Notification Service**: Trigger push notifications for offline users

## Tech Stack

- **Node.js** with ES6 modules
- **Express.js** for REST API
- **Socket.IO** for real-time communication
- **MongoDB** with Mongoose
- **AWS S3** for file storage
- **Kafka** for event-driven architecture
- **JWT** for authentication

## Installation

```bash
cd backend/services/messaging-service
npm install
```

## Configuration

Create a `.env` file:

```env
# Server
PORT=3006
NODE_ENV=development

# MongoDB
MONGODB_URI=mongodb://localhost:27017/esante-messaging

# JWT
JWT_SECRET=your_jwt_secret_key

# Kafka
KAFKA_BROKER=localhost:9092
KAFKA_CLIENT_ID=messaging-service
KAFKA_GROUP_ID=messaging-service-group

# Service URLs
USER_SERVICE_URL=http://localhost:3002
NOTIFICATION_SERVICE_URL=http://localhost:3007

# AWS S3
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
AWS_REGION=us-east-1
AWS_S3_BUCKET=esante-messages

# Frontend
FRONTEND_URL=http://localhost:3000

# Limits
MAX_FILE_SIZE=10485760
MAX_MESSAGE_LENGTH=5000
MESSAGES_PER_PAGE=50
```

## Running the Service

### Development
```bash
npm run dev
```

### Production
```bash
npm start
```

Server will start on port 3006 (or PORT from .env).

## Database Models

### Conversation Model

```javascript
{
  participants: [ObjectId], // Exactly 2 users
  participantTypes: [
    { userId: ObjectId, userType: 'patient' | 'doctor' }
  ],
  conversationType: 'patient_doctor' | 'doctor_doctor',
  lastMessage: {
    content: String,
    senderId: ObjectId,
    timestamp: Date,
    isRead: Boolean
  },
  unreadCount: Map<String, Number>, // userId -> count
  isActive: Boolean,
  isArchived: Boolean,
  createdAt: Date,
  updatedAt: Date
}
```

**Indexes:**
- `participants` (unique compound)
- `participants + lastMessage.timestamp` (desc)
- `conversationType`

### Message Model

```javascript
{
  conversationId: ObjectId,
  senderId: ObjectId,
  senderType: 'patient' | 'doctor',
  receiverId: ObjectId,
  receiverType: 'patient' | 'doctor',
  messageType: 'text' | 'image' | 'document' | 'system',
  content: String,
  attachment: {
    fileName: String,
    fileSize: Number,
    mimeType: String,
    s3Key: String,
    s3Url: String
  },
  isRead: Boolean,
  readAt: Date,
  isDelivered: Boolean,
  deliveredAt: Date,
  isEdited: Boolean,
  editedAt: Date,
  isDeleted: Boolean,
  deletedAt: Date,
  deletedBy: ObjectId,
  metadata: Object,
  createdAt: Date,
  updatedAt: Date
}
```

**Indexes:**
- `conversationId + createdAt` (desc)
- `senderId + createdAt` (desc)
- `receiverId + isRead`
- `content` (text index for search)

## API Endpoints

### 1. Create or Get Conversation

**POST** `/api/v1/messages/conversations`

Create a new conversation or retrieve existing one.

**Headers:**
```
Authorization: Bearer {token}
```

**Request Body:**
```json
{
  "recipientId": "673a1b2c3d4e5f6a7b8c9d0e",
  "recipientType": "doctor"
}
```

**Response:** (201 Created or 200 OK)
```json
{
  "message": "Conversation created successfully",
  "data": {
    "conversationId": "673a1b2c3d4e5f6a7b8c9d0f",
    "conversationType": "patient_doctor",
    "recipient": {
      "id": "673a1b2c3d4e5f6a7b8c9d0e",
      "name": "Dr. Sarah Smith",
      "type": "doctor",
      "profilePhoto": "https://...",
      "specialty": "Cardiology",
      "isOnline": true
    },
    "lastMessage": null,
    "unreadCount": 0,
    "createdAt": "2025-10-29T10:00:00Z",
    "updatedAt": "2025-10-29T10:00:00Z"
  }
}
```

### 2. Get User's Conversations

**GET** `/api/v1/messages/conversations?type=all&page=1&limit=20`

Get list of conversations for authenticated user.

**Query Parameters:**
- `type`: `all`, `patient_doctor`, `doctor_doctor` (default: `all`)
- `page`: Page number (default: 1)
- `limit`: Items per page (default: 20, max: 100)

**Response:** (200 OK)
```json
{
  "message": "Conversations retrieved successfully",
  "data": [
    {
      "conversationId": "...",
      "conversationType": "patient_doctor",
      "recipient": {
        "id": "...",
        "name": "Dr. Sarah Smith",
        "type": "doctor",
        "profilePhoto": "...",
        "isOnline": true
      },
      "lastMessage": {
        "content": "Thank you, Doctor",
        "timestamp": "2025-10-29T15:30:00Z",
        "senderId": "...",
        "isRead": true
      },
      "unreadCount": 0
    }
  ],
  "pagination": {
    "currentPage": 1,
    "totalPages": 3,
    "totalItems": 45,
    "itemsPerPage": 20,
    "hasMore": true,
    "hasPrevious": false
  }
}
```

### 3. Get Conversation Messages

**GET** `/api/v1/messages/conversations/:conversationId/messages?page=1&limit=50`

Get message history for a conversation.

**Query Parameters:**
- `page`: Page number (default: 1)
- `limit`: Messages per page (default: 50, max: 100)
- `before`: Message ID (optional - for pagination)

**Response:** (200 OK)
```json
{
  "message": "Messages retrieved successfully",
  "data": {
    "conversationId": "...",
    "messages": [
      {
        "id": "...",
        "senderId": "...",
        "senderName": "Dr. Sarah Smith",
        "senderType": "doctor",
        "messageType": "text",
        "content": "Hello, how are you feeling today?",
        "isRead": true,
        "readAt": "2025-10-29T14:05:00Z",
        "isDelivered": true,
        "deliveredAt": "2025-10-29T14:00:30Z",
        "createdAt": "2025-10-29T14:00:00Z",
        "isEdited": false,
        "isDeleted": false
      },
      {
        "id": "...",
        "senderId": "...",
        "senderName": "John Doe",
        "senderType": "patient",
        "messageType": "image",
        "content": "Sent an image",
        "attachment": {
          "fileName": "report.jpg",
          "fileSize": 256000,
          "mimeType": "image/jpeg",
          "url": "https://s3.amazonaws.com/..."
        },
        "isRead": false,
        "isDelivered": true,
        "createdAt": "2025-10-29T14:05:00Z"
      }
    ],
    "pagination": {
      "currentPage": 1,
      "totalPages": 5,
      "totalItems": 240,
      "itemsPerPage": 50,
      "hasMore": true
    }
  }
}
```

### 4. Mark Messages as Read

**PUT** `/api/v1/messages/conversations/:conversationId/mark-read`

Mark multiple messages as read.

**Request Body:**
```json
{
  "messageIds": [
    "673a1b2c3d4e5f6a7b8c9d10",
    "673a1b2c3d4e5f6a7b8c9d11"
  ]
}
```

**Response:** (200 OK)
```json
{
  "message": "2 messages marked as read"
}
```

### 5. Send File Message

**POST** `/api/v1/messages/conversations/:conversationId/send-file`

Send a message with file attachment.

**Headers:**
```
Authorization: Bearer {token}
Content-Type: multipart/form-data
```

**Form Data:**
- `file`: File (required)
- `receiverId`: String (required)
- `messageType`: `image` or `document` (required)
- `caption`: String (optional, max 500 chars)

**Response:** (201 Created)
```json
{
  "message": "File sent successfully",
  "data": {
    "id": "...",
    "conversationId": "...",
    "senderId": "...",
    "senderName": "John Doe",
    "messageType": "image",
    "content": "Check this report",
    "attachment": {
      "fileName": "medical_report.jpg",
      "fileSize": 256000,
      "mimeType": "image/jpeg",
      "url": "https://s3.amazonaws.com/..."
    },
    "isRead": false,
    "isDelivered": true,
    "createdAt": "2025-10-29T14:30:00Z"
  }
}
```

### 6. Delete Message

**DELETE** `/api/v1/messages/:messageId`

Soft delete a message (sender only).

**Response:** (200 OK)
```json
{
  "message": "Message deleted successfully"
}
```

### 7. Get Unread Count

**GET** `/api/v1/messages/unread-count`

Get total unread message count for user.

**Response:** (200 OK)
```json
{
  "message": "Unread count retrieved successfully",
  "data": {
    "totalUnread": 15,
    "byConversation": [
      {
        "conversationId": "...",
        "recipientName": "Dr. Sarah Smith",
        "unreadCount": 5
      },
      {
        "conversationId": "...",
        "recipientName": "Dr. Michael Johnson",
        "unreadCount": 10
      }
    ]
  }
}
```

### 8. Search Messages

**GET** `/api/v1/messages/search?query=medication&page=1&limit=20`

Search messages by text content.

**Query Parameters:**
- `query`: Search text (required, min 1 char)
- `conversationId`: Filter by conversation (optional)
- `page`: Page number (default: 1)
- `limit`: Results per page (default: 20, max: 50)

**Response:** (200 OK)
```json
{
  "message": "Search results retrieved successfully",
  "data": {
    "query": "medication",
    "messages": [
      {
        "id": "...",
        "conversationId": "...",
        "senderName": "Dr. Sarah Smith",
        "content": "Your medication dosage should be...",
        "createdAt": "2025-10-28T10:00:00Z"
      }
    ],
    "pagination": {
      "currentPage": 1,
      "totalPages": 2,
      "totalItems": 8
    }
  }
}
```

### 9. Get User Online Status

**GET** `/api/v1/messages/users/:userId/online-status`

Check if a user is currently online.

**Response:** (200 OK)
```json
{
  "message": "Online status retrieved successfully",
  "data": {
    "userId": "673a1b2c3d4e5f6a7b8c9d0e",
    "isOnline": true
  }
}
```

## Socket.IO Events

### Client → Server Events

#### 1. Connect
```javascript
const socket = io('http://localhost:3006', {
  auth: { token: 'your_jwt_token' }
});
```

#### 2. send_message
```javascript
socket.emit('send_message', {
  conversationId: '673a1b2c3d4e5f6a7b8c9d0f',
  receiverId: '673a1b2c3d4e5f6a7b8c9d0e',
  messageType: 'text',
  content: 'Hello, Doctor!',
  tempId: 'temp_123', // Optional: client-side temp ID
  metadata: { /* optional */ }
});
```

#### 3. typing_start
```javascript
socket.emit('typing_start', {
  conversationId: '673a1b2c3d4e5f6a7b8c9d0f',
  receiverId: '673a1b2c3d4e5f6a7b8c9d0e'
});
```

#### 4. typing_stop
```javascript
socket.emit('typing_stop', {
  conversationId: '673a1b2c3d4e5f6a7b8c9d0f',
  receiverId: '673a1b2c3d4e5f6a7b8c9d0e'
});
```

#### 5. mark_as_read
```javascript
socket.emit('mark_as_read', {
  conversationId: '673a1b2c3d4e5f6a7b8c9d0f',
  messageIds: ['msgId1', 'msgId2']
});
```

#### 6. join_conversation
```javascript
socket.emit('join_conversation', {
  conversationId: '673a1b2c3d4e5f6a7b8c9d0f'
});
```

### Server → Client Events

#### 1. message_sent (Confirmation)
```javascript
socket.on('message_sent', (data) => {
  console.log('Message sent:', data);
  // { tempId: 'temp_123', messageId: '...', timestamp: '...' }
});
```

#### 2. new_message (Received)
```javascript
socket.on('new_message', (message) => {
  console.log('New message received:', message);
  // Full message object with sender info
});
```

#### 3. message_delivered
```javascript
socket.on('message_delivered', (data) => {
  console.log('Message delivered:', data);
  // { messageId: '...', deliveredAt: '...' }
});
```

#### 4. messages_read
```javascript
socket.on('messages_read', (data) => {
  console.log('Messages read:', data);
  // { conversationId: '...', messageIds: [...], readBy: '...', readAt: '...' }
});
```

#### 5. user_typing
```javascript
socket.on('user_typing', (data) => {
  console.log('User typing:', data);
  // { conversationId: '...', userId: '...', userName: '...' }
});
```

#### 6. user_stopped_typing
```javascript
socket.on('user_stopped_typing', (data) => {
  console.log('User stopped typing:', data);
  // { conversationId: '...', userId: '...' }
});
```

#### 7. user_online
```javascript
socket.on('user_online', (data) => {
  console.log('User online:', data);
  // { userId: '...', timestamp: ... }
});
```

#### 8. user_offline
```javascript
socket.on('user_offline', (data) => {
  console.log('User offline:', data);
  // { userId: '...', timestamp: ... }
});
```

#### 9. mark_as_read_success
```javascript
socket.on('mark_as_read_success', (data) => {
  console.log('Messages marked as read:', data);
  // { conversationId: '...', messageIds: [...] }
});
```

#### 10. message_deleted
```javascript
socket.on('message_deleted', (data) => {
  console.log('Message deleted:', data);
  // { messageId: '...', conversationId: '...', deletedAt: '...' }
});
```

#### 11. error
```javascript
socket.on('error', (error) => {
  console.error('Socket error:', error);
  // { event: 'send_message', message: 'Error description' }
});
```

## Kafka Events Published

### 1. message.sent
```javascript
{
  eventType: 'message.sent',
  messageId: '673a1b2c3d4e5f6a7b8c9d10',
  conversationId: '673a1b2c3d4e5f6a7b8c9d0f',
  senderId: '673a1b2c3d4e5f6a7b8c9d0a',
  receiverId: '673a1b2c3d4e5f6a7b8c9d0e',
  messageType: 'text',
  timestamp: 1730196000000,
  isReceiverOnline: false
}
```

**Trigger:** Message sent via Socket.IO or REST API

### 2. message.delivered
```javascript
{
  eventType: 'message.delivered',
  messageId: '673a1b2c3d4e5f6a7b8c9d10',
  deliveredAt: 1730196005000
}
```

**Trigger:** Receiver comes online or views conversation

### 3. message.read
```javascript
{
  eventType: 'message.read',
  conversationId: '673a1b2c3d4e5f6a7b8c9d0f',
  messageIds: ['673a1b2c3d4e5f6a7b8c9d10', '673a1b2c3d4e5f6a7b8c9d11'],
  readBy: '673a1b2c3d4e5f6a7b8c9d0e',
  readAt: 1730196010000
}
```

**Trigger:** User marks messages as read

## Inter-Service Communication

### User Service
- **GET** `/api/v1/users/profile/:userId` - Fetch user profile
- **GET** `/api/v1/users/doctors/:doctorId` - Fetch doctor info

## File Upload Specifications

### Allowed File Types

**Images:**
- `image/jpeg`, `image/jpg`, `image/png`, `image/gif`

**Documents:**
- `application/pdf`
- `application/msword` (Word)
- `application/vnd.openxmlformats-officedocument.wordprocessingml.document` (Word .docx)
- `application/vnd.ms-excel` (Excel)
- `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet` (Excel .xlsx)

### File Size Limit
- **Maximum:** 10MB per file

### S3 Storage Path
```
messages/{conversationId}/{timestamp}_{uuid}.{extension}
```

## Security & Validation

### Authentication
- All REST endpoints require JWT token in `Authorization: Bearer {token}` header
- All Socket.IO connections require JWT token in `socket.handshake.auth.token`

### Access Control
- Users can only view conversations they're part of
- Users can only send messages in their conversations
- Users can only delete their own messages
- Patients can only message doctors (not other patients)

### Rate Limiting
- Implement rate limiting on message sending (recommended)
- Prevent spam and abuse

### File Validation
- File type checked against whitelist
- File size enforced (10MB max)
- S3 objects stored with private ACL

## Error Handling

All errors follow the simple `{message}` format:

```json
{
  "message": "Error description"
}
```

### Common Errors

- **400 Bad Request**: Invalid input, file too large, invalid file type
- **401 Unauthorized**: Missing or invalid JWT token
- **403 Forbidden**: Not participant in conversation, cannot message user
- **404 Not Found**: Conversation or message not found
- **500 Internal Server Error**: Server error

## Testing

### 1. Test REST API with Postman

**Create Conversation:**
```bash
POST http://localhost:3006/api/v1/messages/conversations
Authorization: Bearer {doctor_token}
Body: { "recipientId": "{patient_id}", "recipientType": "patient" }
```

**Get Conversations:**
```bash
GET http://localhost:3006/api/v1/messages/conversations?page=1&limit=20
Authorization: Bearer {token}
```

**Send File:**
```bash
POST http://localhost:3006/api/v1/messages/conversations/{conversationId}/send-file
Authorization: Bearer {token}
Form-data:
  file: [select file]
  receiverId: {userId}
  messageType: image
  caption: Optional caption
```

### 2. Test Socket.IO with Client

```javascript
const io = require('socket.io-client');

const socket = io('http://localhost:3006', {
  auth: { token: 'your_jwt_token' }
});

socket.on('connect', () => {
  console.log('Connected');
  
  // Send message
  socket.emit('send_message', {
    conversationId: 'conv123',
    receiverId: 'user456',
    messageType: 'text',
    content: 'Hello!'
  });
});

socket.on('message_sent', (data) => {
  console.log('Sent:', data);
});

socket.on('new_message', (message) => {
  console.log('Received:', message);
});
```

### 3. Test Typing Indicators

```javascript
// Start typing
socket.emit('typing_start', {
  conversationId: 'conv123',
  receiverId: 'user456'
});

// Stop typing after 3 seconds
setTimeout(() => {
  socket.emit('typing_stop', {
    conversationId: 'conv123',
    receiverId: 'user456'
  });
}, 3000);
```

### 4. Test Online Status

Open two browser tabs with different users:
- User A connects → User B receives `user_online` event
- User A disconnects → User B receives `user_offline` event

## Dependencies

```json
{
  "express": "^4.18.2",
  "mongoose": "^7.5.0",
  "socket.io": "^4.6.1",
  "joi": "^17.9.2",
  "axios": "^1.5.0",
  "jsonwebtoken": "^9.0.2",
  "dotenv": "^16.3.1",
  "helmet": "^7.0.0",
  "cors": "^2.8.5",
  "multer": "^1.4.5-lts.1",
  "aws-sdk": "^2.1450.0",
  "uuid": "^9.0.0"
}
```

Total packages: **297** (0 vulnerabilities)

## Architecture Highlights

### Online Users Tracking
- In-memory `Map<userId, socketId>`
- Shared across all socket handlers
- Cleared on disconnect

### Message Flow
1. Client emits `send_message`
2. Server validates and saves to MongoDB
3. Server updates conversation's `lastMessage` and `unreadCount`
4. Server emits `message_sent` to sender (confirmation)
5. If receiver online: emit `new_message`, mark as delivered
6. If receiver offline: Kafka event triggers push notification
7. Server publishes Kafka event for audit

### Read Receipts Flow
1. User views conversation → marks messages as read
2. Server updates messages and resets unread count
3. Server emits `messages_read` to sender
4. Sender UI updates message status

## Future Enhancements

1. **Message Reactions**: Emoji reactions to messages
2. **Voice Messages**: Audio file support
3. **Video Messages**: Video file support
4. **Message Forwarding**: Forward messages to other conversations
5. **Group Messaging**: Support for multi-participant conversations
6. **Message Editing**: Allow editing recent messages
7. **Message Templates**: Pre-defined message templates for doctors
8. **Scheduled Messages**: Send messages at specific times
9. **Message Encryption**: End-to-end encryption
10. **Message Analytics**: Track response times, message volume

## Health Check

```bash
GET http://localhost:3006/health
```

**Response:**
```json
{
  "service": "Messaging Service",
  "status": "healthy",
  "timestamp": "2025-10-29T10:00:00.000Z",
  "onlineUsers": 15
}
```

## Troubleshooting

### Socket Connection Failed
- Verify JWT token is valid
- Check FRONTEND_URL in .env matches client origin
- Ensure CORS is properly configured

### Messages Not Delivered
- Check receiver is online (`onlineUsers` map)
- Verify Kafka producer is connected
- Check MongoDB connection

### File Upload Failed
- Verify AWS credentials in .env
- Check file size < 10MB
- Ensure file type is allowed
- Verify S3 bucket exists and has correct permissions

---

**Status:** ✅ Production Ready  
**Port:** 3006  
**Database:** esante-messaging  
**Dependencies:** 297 packages, 0 vulnerabilities
