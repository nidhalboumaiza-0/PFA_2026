# Backend Development Prompts - Quick Reference

## 📋 All Prompts at a Glance

| # | Prompt File | Service | Key Features | Estimated Time |
|---|-------------|---------|--------------|----------------|
| 1A | PROMPT_1A_Folder_Structure_MongoDB.md | **Infrastructure - Part 1** | Folder structure, MongoDB connection, Environment setup | 1-2 hours |
| 1B | PROMPT_1B_Shared_Middleware_Utilities.md | **Infrastructure - Part 2** | Auth middleware, Error handling, Validation, Utilities | 2-3 hours |
| 1C | PROMPT_1C_Kafka_Infrastructure.md | **Infrastructure - Part 3** | Kafka setup, Producer/Consumer, Topics, Event schemas | 2-3 hours |
| 1D | PROMPT_1D_API_Gateway.md | **Infrastructure - Part 4** | API Gateway, Routing, Rate limiting, Docker Compose | 2-3 hours |
| 2A | PROMPT_2A_Auth_Core.md | **Auth Service - Part 1** | User model, Register, Login, JWT tokens, Refresh token | 2-3 hours |
| 2B | PROMPT_2B_Auth_Email_Password.md | **Auth Service - Part 2** | Email verification, Forgot/Reset password, Nodemailer | 2-3 hours |
| 3 | PROMPT_3_Service_Users.md | **User Service** | Profiles, S3 photo upload, Doctor search, Geolocation | 3-4 hours |
| 4 | PROMPT_4_Service_RDV.md | **Appointment Service** | Availability, Booking, Confirm/Reject, History | 3-4 hours |
| 5 | PROMPT_5_Medical_Records_Consultations.md | **Medical Records - Part 1** | Consultations, Medical notes, Patient timeline | 3-4 hours |
| 6 | PROMPT_6_Medical_Records_Prescriptions.md | **Medical Records - Part 2** | Prescriptions, 1-hour edit window, Auto-lock | 3-4 hours |
| 7 | PROMPT_7_Medical_Records_Documents.md | **Medical Records - Part 3** | S3 documents, PDF/images, Signed URLs | 3-4 hours |
| 8 | PROMPT_8_Service_Referrals.md | **Referral Service** | Doctor referrals, Specialist search, Referral booking | 3-4 hours |
| 9 | PROMPT_9_Service_Messaging.md | **Messaging Service** | Socket.IO chat, Real-time, Typing indicators | 4-5 hours |
| 10 | PROMPT_10_Service_Notifications.md | **Notification Service** | OneSignal push, Emails, Kafka consumers | 3-4 hours |
| 11 | PROMPT_11_Service_Audit.md | **Audit Service** | Activity logging, Access tracking, Security monitoring | 3-4 hours |
| 12 | PROMPT_12_Kafka_Integration.md | **Kafka Integration** | Full event bus integration across all services | 2-3 hours |
| 13 | PROMPT_13_API_Gateway.md | **API Gateway Final** | Complete integration, Production preparation | 2-3 hours |

**Total Estimated Time:** 48-65 hours of development (split into smaller, manageable chunks)

---

## 🎯 Quick Start Commands

### Give these commands to your AI assistant:

**Command 1: Start with Infrastructure Foundation**
```
I want to build a professional healthcare backend for the E-Santé project.
Please read and implement PROMPT_1A_Folder_Structure_MongoDB.md completely.
Create all folder structures and MongoDB setup as specified.
```

**Command 2: Continue with Shared Middleware**
```
Now implement PROMPT_1B_Shared_Middleware_Utilities.md.
Build all reusable middleware and utility functions.
```

**Command 3: Setup Kafka**
```
Now implement PROMPT_1C_Kafka_Infrastructure.md.
Setup Apache Kafka with producers, consumers, and topics.
```

**Command 4: Setup API Gateway**
```
Now implement PROMPT_1D_API_Gateway.md.
Create the API Gateway with routing and rate limiting.
```

**Command 5: Build Auth Service - Core**
```
Now implement PROMPT_2A_Auth_Core.md.
Build user registration, login, and JWT token management.
```

**Command 6: Complete Auth Service**
```
Now implement PROMPT_2B_Auth_Email_Password.md.
Add email verification and password reset functionality.
```

**Commands 7-18: Continue sequentially**
```
Now implement PROMPT_[X]_[ServiceName].md
```

---

## 🔑 Key Architecture Decisions

### Why Microservices?
- **Scalability:** Each service can scale independently
- **Maintainability:** Clear separation of concerns
- **Team Development:** Multiple developers can work simultaneously
- **Fault Isolation:** One service failure doesn't crash entire system

### Why Apache Kafka?
- **Async Communication:** Services don't need to wait for each other
- **Event Sourcing:** Complete audit trail of all actions
- **Decoupling:** Services don't need to know about each other
- **Reliability:** Message persistence and replay capability

### Why JWT Tokens?
- **Stateless:** No server-side session storage needed
- **Scalable:** Works across multiple service instances
- **Secure:** Cryptographically signed
- **Mobile-Friendly:** Easy to implement in Flutter apps

### Why AWS S3?
- **Scalable Storage:** Unlimited capacity
- **Cost-Effective:** Pay only for what you use
- **Secure:** Private buckets with signed URLs
- **Reliable:** 99.999999999% durability

---

## 📊 System Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        CLIENT APPS                           │
│              Flutter Mobile    |    Next.js Web              │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ↓
┌─────────────────────────────────────────────────────────────┐
│                     API GATEWAY :3000                        │
│  • Authentication     • Rate Limiting    • Request Routing   │
└─────────────────────┬───────────────────────────────────────┘
                      │
      ┌───────────────┼───────────────┬───────────────┐
      ↓               ↓               ↓               ↓
┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐
│   Auth   │   │  Users   │   │   RDV    │   │ Medical  │
│  :3001   │   │  :3002   │   │  :3003   │   │  :3004   │
└────┬─────┘   └────┬─────┘   └────┬─────┘   └────┬─────┘
     │              │              │              │
     └──────────────┴──────────────┴──────────────┘
                      │
                      ↓
┌─────────────────────────────────────────────────────────────┐
│                    APACHE KAFKA (Event Bus)                  │
└─────────────────────┬───────────────────────────────────────┘
                      │
      ┌───────────────┼───────────────┬───────────────┐
      ↓               ↓               ↓               ↓
┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐
│Referrals │   │ Messages │   │  Notifs  │   │  Audit   │
│  :3005   │   │  :3006   │   │  :3007   │   │  :3008   │
└──────────┘   └──────────┘   └──────────┘   └──────────┘
      │              │              │              │
      └──────────────┴──────────────┴──────────────┘
                      │
                      ↓
      ┌───────────────┴───────────────┐
      ↓                               ↓
┌──────────────┐              ┌─────────────┐
│   MongoDB    │              │   AWS S3    │
│  (Database)  │              │  (Storage)  │
└──────────────┘              └─────────────┘
```

---

## 🗂️ Database Collections

### Auth Service
- `users` - User accounts and credentials

### User Service
- `patients` - Patient profiles
- `doctors` - Doctor profiles

### RDV Service
- `appointments` - Appointment bookings
- `timeSlots` - Doctor availability

### Medical Records Service
- `consultations` - Medical consultations
- `prescriptions` - Prescriptions with medications
- `medicalDocuments` - Document metadata

### Referral Service
- `referrals` - Doctor-to-doctor referrals

### Messaging Service
- `conversations` - Chat conversations
- `messages` - Chat messages

### Notification Service
- `notifications` - Push/email notifications
- `notificationPreferences` - User preferences

### Audit Service
- `auditLogs` - Complete activity logs

---

## 🔄 Event Flow Examples

### Example 1: Patient Books Appointment
```
1. Patient requests appointment (RDV Service)
   ↓ Publishes: appointment.requested
   
2. Notification Service receives event
   ↓ Sends notification to doctor
   
3. Audit Service receives event
   ↓ Logs appointment request
   
4. Doctor confirms (RDV Service)
   ↓ Publishes: appointment.confirmed
   
5. Notification Service receives event
   ↓ Sends confirmation to patient
   
6. Audit Service logs confirmation
```

### Example 2: Doctor Creates Prescription
```
1. Doctor creates consultation (Medical Service)
   ↓ Publishes: consultation.created
   
2. Doctor adds prescription (Medical Service)
   ↓ Publishes: prescription.created
   ↓ Starts 1-hour edit timer
   
3. Notification Service receives event
   ↓ Notifies patient
   
4. After 1 hour: Auto-lock prescription
   ↓ Publishes: prescription.locked
   
5. Audit Service logs all actions
```

---

## 🧪 Testing Checklist

After completing all prompts, test these scenarios:

### Patient Workflows
- [ ] Register new patient account
- [ ] Verify email address
- [ ] Login and receive JWT token
- [ ] Update profile information
- [ ] Upload profile photo to S3
- [ ] Search for doctors by specialty
- [ ] View doctor on map
- [ ] Request appointment
- [ ] View appointment history
- [ ] Receive appointment confirmation notification
- [ ] Chat with doctor
- [ ] View medical history
- [ ] View prescriptions
- [ ] Download medical documents

### Doctor Workflows
- [ ] Register doctor account with specialty
- [ ] Complete profile with clinic location
- [ ] Set weekly availability
- [ ] View appointment requests
- [ ] Confirm appointment
- [ ] Reject appointment
- [ ] Create consultation after appointment
- [ ] Write prescription (multiple medications)
- [ ] Edit prescription within 1 hour
- [ ] Upload patient document to S3
- [ ] View patient medical timeline
- [ ] Create referral to specialist
- [ ] Book appointment for referred patient
- [ ] Chat with patient
- [ ] Chat with another doctor
- [ ] Receive notifications

### Admin Workflows
- [ ] View all audit logs
- [ ] Filter logs by category
- [ ] View user activity history
- [ ] Track patient record access
- [ ] Monitor security events
- [ ] Export audit logs
- [ ] View system statistics

### System Tests
- [ ] JWT authentication across all services
- [ ] Kafka events flow correctly
- [ ] MongoDB indexes working
- [ ] S3 uploads and signed URLs
- [ ] Socket.IO real-time messaging
- [ ] OneSignal push notifications
- [ ] Email sending (Nodemailer)
- [ ] Rate limiting prevents abuse
- [ ] API Gateway routes correctly
- [ ] Docker Compose brings up all services
- [ ] Health checks report correctly

---

## 📦 Deliverables Summary

After completing all 13 prompts, you will have:

### Backend Services (8)
✅ Authentication Service
✅ User Management Service
✅ Appointment Service
✅ Medical Records Service
✅ Referral Service
✅ Messaging Service
✅ Notification Service
✅ Audit/Logging Service

### Infrastructure
✅ API Gateway with routing
✅ Apache Kafka event bus
✅ MongoDB database schemas
✅ Redis caching & rate limiting
✅ AWS S3 file storage
✅ Docker Compose orchestration

### Features
✅ 100+ API endpoints
✅ Real-time chat (Socket.IO)
✅ Push notifications (OneSignal)
✅ Email notifications (Nodemailer)
✅ Geolocation search (Google Maps)
✅ File uploads (AWS S3)
✅ Complete audit trail
✅ Role-based access control
✅ JWT authentication

### Documentation
✅ API endpoint documentation
✅ Database schema documentation
✅ Event schemas
✅ Environment setup guide
✅ Testing guidelines

---

## 🚀 What to Do with These Files

### Step 1: Read the Master README
Start with `README_BACKEND_PROMPTS.md` to understand the overall structure.

### Step 2: Begin with Prompt 1
Open `PROMPT_1_Project_Structure.md` and give it to your AI assistant to implement.

### Step 3: Work Sequentially
Complete prompts 1-13 in order. Each builds upon the previous ones.

### Step 4: Test After Each Prompt
Use Postman or similar tools to test the APIs after each service is built.

### Step 5: Deploy
Once all prompts are complete, deploy to your production environment.

---

## 📞 Getting Help

If you need clarification on any prompt:
1. Read the specific prompt file carefully
2. Check the main README for context
3. Ask your AI assistant specific questions about the implementation
4. Refer to official documentation of the technologies used

---

**Ready to build? Start with PROMPT_1_Project_Structure.md! 🎉**
