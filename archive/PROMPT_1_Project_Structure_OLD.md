# PROMPT 1: Project Structure & Configuration

## Objective
Setup the complete microservices folder structure, shared utilities, configuration files, and API Gateway foundation for the E-Santé backend platform.

## Requirements

### 1. Explore Current Backend
- Analyze existing backend folder structure
- Identify what already exists
- Document current state

### 2. Create Microservices Architecture Structure
```
backend/
├── api-gateway/          # Central API Gateway
├── services/
│   ├── auth-service/     # Authentication & Authorization
│   ├── user-service/     # User Management
│   ├── rdv-service/      # Appointments
│   ├── medical-records-service/  # Medical Records
│   ├── referral-service/ # Doctor Referrals
│   ├── messaging-service/# Communication
│   ├── notification-service/ # Notifications
│   └── audit-service/    # Activity Logging
├── shared/               # Shared utilities & configs
│   ├── utils/
│   ├── middleware/
│   ├── config/
│   └── kafka/
├── docker-compose.yml    # Container orchestration
└── package.json          # Root package management
```

### 3. Shared Utilities Setup

#### a) Database Connection (MongoDB)
- MongoDB connection helper
- Connection pooling
- Error handling
- Retry logic

#### b) Kafka Configuration
- Kafka producer setup
- Kafka consumer setup
- Event schemas
- Topic management

#### c) Common Middleware
- JWT authentication middleware
- Error handling middleware
- Request logging middleware
- Rate limiting middleware
- CORS configuration

#### d) Utility Functions
- Response formatter
- Error classes
- Validation helpers
- Date/time utilities
- File upload helpers (S3)

### 4. Environment Variables Template
Create `.env.example` with:
```
# Server
NODE_ENV=development
PORT=3000

# MongoDB
MONGODB_URI=mongodb://localhost:27017/esante
MONGODB_TEST_URI=mongodb://localhost:27017/esante_test

# JWT
JWT_SECRET=your_jwt_secret_here
JWT_EXPIRE=7d
JWT_REFRESH_SECRET=your_refresh_secret_here
JWT_REFRESH_EXPIRE=30d

# Email (Nodemailer)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your_email@gmail.com
SMTP_PASS=your_app_password
EMAIL_FROM=noreply@esante.com

# AWS S3
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
AWS_REGION=us-east-1
AWS_S3_BUCKET=esante-medical-documents

# OneSignal
ONESIGNAL_APP_ID=your_app_id
ONESIGNAL_REST_API_KEY=your_api_key

# Kafka
KAFKA_BROKERS=localhost:9092
KAFKA_CLIENT_ID=esante-backend

# Google Maps
GOOGLE_MAPS_API_KEY=your_google_maps_key

# Frontend URLs
FRONTEND_URL=http://localhost:3000
ADMIN_URL=http://localhost:3001
```

### 5. API Gateway Setup

#### Features Needed:
- Central entry point for all services
- Route forwarding to microservices
- Authentication check
- Request/response logging
- Rate limiting
- Error handling
- Health check endpoints

#### Gateway Routes Structure:
```
/api/v1/auth/*          → auth-service
/api/v1/users/*         → user-service
/api/v1/appointments/*  → rdv-service
/api/v1/medical/*       → medical-records-service
/api/v1/referrals/*     → referral-service
/api/v1/messages/*      → messaging-service
/api/v1/notifications/* → notification-service
/api/v1/audit/*         → audit-service
```

### 6. Package.json Dependencies

#### Core Dependencies:
- express
- mongoose
- jsonwebtoken
- bcryptjs
- dotenv
- cors
- helmet
- express-rate-limit
- morgan

#### Kafka:
- kafkajs

#### Email:
- nodemailer

#### AWS:
- aws-sdk / @aws-sdk/client-s3

#### Real-time:
- socket.io

#### Validation:
- joi / express-validator

#### Utils:
- moment / date-fns
- uuid
- multer

#### Dev Dependencies:
- nodemon
- eslint
- prettier

### 7. Docker Configuration (Optional but Recommended)
- Docker Compose for local development
- MongoDB container
- Kafka + Zookeeper containers
- Service containers

## Deliverables
1. ✅ Complete folder structure
2. ✅ Shared utilities and middleware
3. ✅ Database connection helper
4. ✅ Kafka configuration setup
5. ✅ Environment variables template
6. ✅ API Gateway foundation
7. ✅ Package.json with all dependencies
8. ✅ README with setup instructions

## Success Criteria
- All folders created with proper structure
- Shared utilities are reusable across services
- API Gateway can route to service placeholders
- Environment variables are properly documented
- MongoDB connection works
- Basic error handling is in place

---

**Next Step:** After this prompt is complete, proceed to PROMPT 2 (Service Auth)
