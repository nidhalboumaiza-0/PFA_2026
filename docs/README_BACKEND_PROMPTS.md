# E-Santé Backend Development - Complete Guide

## 📚 Overview

This directory contains **16 comprehensive prompts** (split into manageable pieces) to build a professional, production-ready microservices backend for the E-Santé platform. Each prompt is designed to be given to an AI assistant (like Copilot) to implement specific parts of the system.

## 🎯 Project Goals

Build a complete healthcare platform backend with:
- **Microservices Architecture** with Apache Kafka event bus
- **Authentication & Authorization** with email verification
- **Medical Records Management** with consultations, prescriptions, and documents
- **Doctor Referral System** with appointment booking
- **Real-time Messaging** using Socket.IO
- **Push Notifications** via OneSignal
- **Complete Audit Logging** for compliance
- **AWS S3 Integration** for document storage
- **Professional API Gateway** as single entry point

## 📋 Execution Order

### **Phase 1: Infrastructure Setup** (Start Here - CRITICAL)
These prompts set up the foundation that all services depend on:

1. **PROMPT_1A_Folder_Structure_MongoDB.md**
   - Setup microservices folder structure
   - Configure MongoDB connection with retry logic
   - Create environment variables template
   - **Time estimate:** 1-2 hours

2. **PROMPT_1B_Shared_Middleware_Utilities.md**
   - Authentication middleware (JWT)
   - Error handling with custom error classes
   - Validation helpers
   - Response formatters and date utilities
   - **Time estimate:** 2-3 hours

3. **PROMPT_1C_Kafka_Infrastructure.md**
   - Setup Apache Kafka event bus
   - Create producer/consumer utilities
   - Define topics and event schemas
   - Docker Compose for Kafka
   - **Time estimate:** 2-3 hours

4. **PROMPT_1D_API_Gateway.md**
   - Create API Gateway with Express
   - Service proxying and routing
   - Rate limiting with Redis
   - Health checks
   - Complete Docker Compose
   - **Time estimate:** 2-3 hours

### **Phase 2: Authentication Services**
5. **PROMPT_2A_Auth_Core.md**
   - User registration (Patient/Doctor)
   - Login/logout with JWT tokens
   - Token refresh mechanism
   - **Time estimate:** 2-3 hours

6. **PROMPT_2B_Auth_Email_Password.md**
   - Email verification with Nodemailer
   - Password reset flow
   - Change password functionality
   - **Time estimate:** 2-3 hours

### **Phase 3: Core Services**
7. **PROMPT_3_Service_Users.md**
   - Patient/Doctor profile management
   - Photo upload to AWS S3
   - Doctor search with geolocation
   - **Time estimate:** 3-4 hours

8. **PROMPT_4_Service_RDV.md**
   - Doctor availability management
   - Patient appointment requests
   - Doctor confirm/reject workflow
   - Appointment history
   - **Time estimate:** 3-4 hours

### **Phase 4: Medical Records** (Core Features)
9. **PROMPT_5_Medical_Records_Consultations.md**
   - Consultation creation and management
   - Patient medical timeline
   - Cross-doctor visibility
   - **Time estimate:** 3-4 hours

10. **PROMPT_6_Medical_Records_Prescriptions.md**
    - Prescription with multiple medications
    - 1-hour edit window with auto-lock
    - Modification history tracking
    - **Time estimate:** 3-4 hours

11. **PROMPT_7_Medical_Records_Documents.md**
   - Upload documents to AWS S3 (PDF/images)
   - Document types: lab results, imaging, prescriptions, insurance
   - Signed URLs for secure access
   - **Time estimate:** 3-4 hours

### **Phase 5: Referrals & Communication**
12. **PROMPT_8_Service_Referrals.md**
   - Doctor-to-doctor referrals
   - Search specialists
   - Book appointments for patients
   - Referral workflow tracking
   - **Time estimate:** 3-4 hours

13. **PROMPT_9_Service_Messaging.md**
    - Real-time messaging with Socket.IO
    - Patient-doctor and doctor-doctor chat
    - Message history and typing indicators
    - **Time estimate:** 4-5 hours

### **Phase 6: Notifications & Audit**
14. **PROMPT_10_Service_Notifications.md**
    - OneSignal push notifications
    - Email notifications with Nodemailer
    - User preferences management
    - Kafka event consumers
    - **Time estimate:** 3-4 hours

15. **PROMPT_11_Service_Audit.md**
    - Complete activity logging
    - Track all medical record access
    - Security event monitoring
    - Admin dashboard queries
    - **Time estimate:** 3-4 hours

### **Phase 7: Final Integration**
16. **PROMPT_12_Kafka_Integration.md**
    - Setup Apache Kafka event bus
    - Producer/consumer utilities
    - Event schemas and topic management
    - Service-to-service communication
    - **Time estimate:** 2-3 hours

17. **PROMPT_13_API_Gateway.md**
    - Final API Gateway integration
    - Complete service routing
    - Production deployment preparation
    - **Time estimate:** 2-3 hours

## 🚀 How to Use These Prompts

### Step-by-Step Process:

1. **Start with Prompt 1A (Infrastructure Foundation):**
   ```
   Open PROMPT_1A_Folder_Structure_MongoDB.md and give it to Copilot:
   
   "Please implement everything in PROMPT_1A_Folder_Structure_MongoDB.md. 
   Create all the folder structures and MongoDB setup as specified."
   ```

2. **Wait for completion and test:**
   - Verify the folder structure was created
   - Check that MongoDB connection works
   - Ensure shared utilities are in place

3. **Continue with remaining infrastructure prompts:**
   - Then PROMPT_1B (Shared Middleware)
   - Then PROMPT_1C (Kafka)
   - Then PROMPT_1D (API Gateway)

4. **Move to Prompt 2 (Auth Service):**
   ```
   "Now implement PROMPT_2_Service_Auth.md. 
   Create the authentication service with all endpoints specified."
   ```

5. **Test each service:**
   - Test user registration
   - Verify email sending works
   - Test login and JWT token generation

6. **Continue sequentially** through all 16 prompts

7. **Test integration** after each phase:
   - Phase 1: Test infrastructure (MongoDB, Kafka, Gateway)
   - Phase 2: Test auth and user management
   - Phase 2: Test appointment booking
   - Phase 3: Test medical records
   - Phase 4: Test referrals and messaging
   - Phase 5: Test notifications
   - Phase 6: Test full system integration

## 📁 Expected Final Structure

```
backend/
├── api-gateway/                    # Central API Gateway
│   ├── src/
│   │   ├── config/
│   │   ├── middleware/
│   │   ├── routes/
│   │   └── index.js
│   └── package.json
│
├── services/
│   ├── auth-service/               # Authentication & Authorization
│   ├── user-service/               # User Management
│   ├── rdv-service/                # Appointments
│   ├── medical-records-service/    # Consultations, Prescriptions, Documents
│   ├── referral-service/           # Doctor Referrals
│   ├── messaging-service/          # Real-time Chat
│   ├── notification-service/       # Push & Email Notifications
│   └── audit-service/              # Activity Logging
│
├── shared/                         # Shared utilities
│   ├── config/
│   │   ├── database.js
│   │   └── kafka.config.js
│   ├── middleware/
│   │   ├── auth.middleware.js
│   │   ├── error.middleware.js
│   │   └── validation.middleware.js
│   ├── utils/
│   │   ├── response.js
│   │   ├── s3.helper.js
│   │   └── email.helper.js
│   └── kafka/
│       ├── producer.js
│       ├── consumer.js
│       └── topics.js
│
├── docker-compose.yml              # Container orchestration
├── .env.example                    # Environment variables template
└── README.md                       # Documentation
```

## 🛠️ Technology Stack

### Core Technologies:
- **Runtime:** Node.js
- **Framework:** Express.js
- **Database:** MongoDB
- **Cache/Session:** Redis
- **Message Broker:** Apache Kafka
- **Real-time:** Socket.IO
- **File Storage:** AWS S3
- **Push Notifications:** OneSignal
- **Email:** Nodemailer
- **Maps:** Google Maps API

### Key Libraries:
- `express` - Web framework
- `mongoose` - MongoDB ODM
- `jsonwebtoken` - JWT authentication
- `bcryptjs` - Password hashing
- `kafkajs` - Kafka client
- `socket.io` - WebSocket
- `nodemailer` - Email sending
- `aws-sdk` - AWS integration
- `onesignal-node` - Push notifications

## ⚙️ Prerequisites

Before starting, ensure you have:

1. **Node.js** (v18+)
2. **MongoDB** (v6+)
3. **Docker** & Docker Compose
4. **AWS Account** (for S3)
5. **OneSignal Account** (for push notifications)
6. **Gmail Account** (for email sending) or SMTP server

## 🔐 Environment Setup

Each prompt will guide you to configure environment variables. Keep these ready:

```bash
# Database
MONGODB_URI=mongodb://localhost:27017/esante

# JWT Secrets
JWT_SECRET=your_super_secret_key
JWT_REFRESH_SECRET=your_refresh_secret

# AWS S3
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
AWS_S3_BUCKET=esante-medical-documents

# Email (Gmail)
SMTP_USER=your_email@gmail.com
SMTP_PASS=your_app_specific_password

# OneSignal
ONESIGNAL_APP_ID=your_app_id
ONESIGNAL_REST_API_KEY=your_api_key

# Google Maps
GOOGLE_MAPS_API_KEY=your_google_maps_key
```

## 🧪 Testing Strategy

After each prompt implementation:

### 1. Unit Testing
- Test individual functions and utilities
- Test database models and schemas

### 2. Integration Testing
- Test API endpoints with Postman/Insomnia
- Test service-to-service communication
- Test Kafka event flow

### 3. End-to-End Testing
- Test complete user journeys:
  - Patient registration → search doctor → book appointment
  - Doctor login → view appointments → create consultation
  - Doctor referral flow
  - Messaging between users

### Recommended Tools:
- **Postman** - API testing
- **Kafka UI** - Monitor Kafka topics
- **MongoDB Compass** - Database inspection
- **Socket.IO Client** - WebSocket testing

## 📊 Key Features Implemented

### For Patients:
✅ Registration with email verification
✅ Search doctors by specialty/location
✅ Book appointments
✅ View appointment history
✅ Access medical records
✅ View prescriptions
✅ Upload medical documents
✅ Chat with doctors
✅ Receive notifications

### For Doctors:
✅ Professional profile management
✅ Set availability
✅ Manage appointment requests
✅ Create consultations
✅ Write prescriptions (with 1-hour edit window)
✅ Upload patient documents
✅ View patient medical history
✅ Refer patients to specialists
✅ Chat with patients and other doctors
✅ Receive notifications

### For Admins:
✅ View all system activity
✅ Monitor user actions
✅ Track medical record access
✅ Security event monitoring
✅ Generate compliance reports

## 🔒 Security Features

- ✅ Password hashing with bcrypt
- ✅ JWT token authentication
- ✅ Email verification required
- ✅ Rate limiting on API endpoints
- ✅ CORS protection
- ✅ Helmet.js security headers
- ✅ Input validation and sanitization
- ✅ AWS S3 signed URLs (no public access)
- ✅ Complete audit logging
- ✅ HIPAA/GDPR compliance considerations

## 📈 Scalability Features

- ✅ Microservices architecture
- ✅ Apache Kafka for async communication
- ✅ Redis for caching and rate limiting
- ✅ MongoDB with proper indexing
- ✅ AWS S3 for scalable storage
- ✅ Docker containerization
- ✅ Load balancer ready (API Gateway)

## 🐛 Troubleshooting

### Common Issues:

**MongoDB Connection Failed:**
- Check MongoDB is running: `docker ps`
- Verify connection string in .env
- Check firewall settings

**Kafka Not Connecting:**
- Ensure Zookeeper is running first
- Check KAFKA_BROKERS environment variable
- Verify Docker network connectivity

**Email Not Sending:**
- Enable "Less secure app access" in Gmail (or use App Password)
- Check SMTP credentials
- Verify firewall allows SMTP port

**AWS S3 Upload Failing:**
- Verify AWS credentials
- Check IAM permissions
- Ensure bucket exists and is accessible

## 📝 Next Steps After Completion

1. **Mobile App (Flutter):**
   - Connect to API Gateway
   - Implement UI for all features
   - Integrate Google Maps
   - Setup OneSignal push notifications

2. **Web Admin (Next.js):**
   - Admin dashboard
   - User management
   - Statistics and analytics
   - Audit log viewer

3. **Production Deployment:**
   - Setup AWS EC2 or Cloud provider
   - Configure NGINX reverse proxy
   - Setup MongoDB Atlas
   - Configure AWS CloudFront for S3
   - Implement monitoring (PM2, CloudWatch)

4. **Additional Features:**
   - Video consultation (WebRTC)
   - Payment integration
   - Insurance claim processing
   - Prescription QR codes
   - Lab result integration

## 💡 Tips for Success

1. **Work sequentially** - Don't skip prompts
2. **Test thoroughly** - After each prompt, test all endpoints
3. **Keep logs** - Monitor console output for errors
4. **Use version control** - Commit after each prompt
5. **Read carefully** - Each prompt has specific requirements
6. **Ask questions** - If something is unclear, ask for clarification
7. **Document changes** - Keep notes on any modifications you make

## 🤝 Support & Questions

If you encounter issues or have questions:
1. Review the specific prompt file for details
2. Check the troubleshooting section
3. Ask your AI assistant for clarification
4. Refer to official documentation of libraries used

## 📄 License

This project structure is designed for the E-Santé educational project.

---

**Good luck with your implementation! 🚀**

Start with PROMPT_1_Project_Structure.md and work your way through sequentially!
