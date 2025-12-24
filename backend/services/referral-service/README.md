# Referral Service - Doctor-to-Doctor Referrals

## Overview
The Referral Service manages doctor-to-doctor patient referrals, allowing general practitioners to refer patients to specialists, search for specialists, book appointments on behalf of patients, and track the complete referral workflow.

## Features

### Doctor Features (Referring Doctor)
- **Create Referrals**
  - Refer patients to specialists with complete medical context
  - Attach relevant medical documents
  - Set urgency levels (routine, urgent, emergency)
  - Specify preferred appointment dates
  
- **Search Specialists**
  - Search by specialty and location
  - View specialist profiles and availability
  - Filter by distance and ratings
  
- **Appointment Management**
  - Book appointments on behalf of patients
  - Auto-confirm referral appointments
  - Link appointments to referrals
  
- **Track Referrals**
  - View all sent referrals
  - Monitor referral status
  - Receive feedback from specialists
  - View referral statistics

### Doctor Features (Target/Specialist Doctor)
- **Receive Referrals**
  - View incoming referrals with complete patient history
  - Filter by urgency and status
  - Access attached medical documents
  
- **Respond to Referrals**
  - Accept referrals with response notes
  - Reject referrals with suggested alternatives
  - Provide feedback after consultation
  
- **Complete Workflow**
  - Mark referrals as completed
  - Provide feedback to referring doctor
  - Link to created consultations
  
- **Statistics**
  - Track received referrals
  - View top referring doctors
  - Monitor completion rates

### Patient Features
- **View Referrals**
  - See all referrals created for them
  - View referral status and appointment details
  - Access doctor information
  
- **Cancel Referrals**
  - Cancel referrals if no longer needed
  - Provide cancellation reason

## API Endpoints

### Doctor Endpoints (Referring)
```
POST   /api/v1/referrals                              # Create referral
GET    /api/v1/referrals/search-specialists           # Search specialists
POST   /api/v1/referrals/:id/book-appointment         # Book appointment
GET    /api/v1/referrals/sent                         # View sent referrals
GET    /api/v1/referrals/statistics                   # Referral statistics
```

### Doctor Endpoints (Target)
```
GET    /api/v1/referrals/received                     # View received referrals
PUT    /api/v1/referrals/:id/accept                   # Accept referral
PUT    /api/v1/referrals/:id/reject                   # Reject referral
PUT    /api/v1/referrals/:id/complete                 # Complete referral
GET    /api/v1/referrals/statistics                   # Referral statistics
```

### Patient Endpoints
```
GET    /api/v1/referrals/my-referrals                 # View my referrals
```

### Shared Endpoints
```
GET    /api/v1/referrals/:id                          # Get referral details
PUT    /api/v1/referrals/:id/cancel                   # Cancel referral
```

## Referral Workflow

### 1. Create Referral
```http
POST /api/v1/referrals
Authorization: Bearer {doctorToken}

{
  "patientId": "65a123...",
  "targetDoctorId": "65b456...",
  "reason": "Patient requires cardiology consultation for suspected coronary artery disease",
  "urgency": "urgent",
  "specialty": "Cardiology",
  "diagnosis": "Suspected angina pectoris with elevated cardiac enzymes",
  "symptoms": ["Chest pain", "Shortness of breath", "Fatigue"],
  "relevantHistory": "5-year history of hypertension...",
  "currentMedications": "Aspirin 100mg daily...",
  "specificConcerns": "Please evaluate for possible coronary angiography",
  "attachedDocuments": ["docId1", "docId2"],
  "preferredDates": ["2025-11-20", "2025-11-21"],
  "referralNotes": "Please prioritize this patient"
}
```

**Response:**
```json
{
  "message": "Referral created successfully. Target doctor will be notified.",
  "referral": {
    "id": "65c789...",
    "targetDoctor": {
      "id": "65b456...",
      "name": "Dr. Emily Johnson",
      "specialty": "Cardiology"
    },
    "patient": {
      "id": "65a123...",
      "name": "John Doe"
    },
    "status": "pending",
    "urgency": "urgent",
    "expiryDate": "2026-02-10"
  }
}
```

### 2. Search Specialists
```http
GET /api/v1/referrals/search-specialists?specialty=cardiology&city=paris&radius=10
Authorization: Bearer {doctorToken}
```

**Response:**
```json
{
  "specialists": [
    {
      "id": "65b456...",
      "name": "Dr. Emily Johnson",
      "specialty": "Cardiology",
      "subSpecialty": "Interventional Cardiology",
      "clinicName": "Heart Center",
      "distance": 3.2,
      "rating": 4.8,
      "yearsOfExperience": 15,
      "consultationFee": 120
    }
  ],
  "pagination": {...}
}
```

### 3. Book Appointment for Referral
```http
POST /api/v1/referrals/65c789.../book-appointment
Authorization: Bearer {doctorToken}

{
  "appointmentDate": "2025-11-20",
  "appointmentTime": "14:00",
  "notes": "Urgent consultation requested"
}
```

**Response:**
```json
{
  "message": "Appointment booked successfully for patient",
  "referral": {
    "id": "65c789...",
    "appointmentId": "65d012...",
    "appointmentDate": "2025-11-20",
    "appointmentTime": "14:00",
    "targetDoctor": "Dr. Emily Johnson",
    "status": "scheduled"
  }
}
```

### 4. Target Doctor Views Received Referrals
```http
GET /api/v1/referrals/received?status=pending&urgency=urgent
Authorization: Bearer {targetDoctorToken}
```

**Response:**
```json
{
  "referrals": [
    {
      "id": "65c789...",
      "referralDate": "2025-11-10",
      "urgency": "urgent",
      "status": "pending",
      "patient": {
        "id": "65a123...",
        "name": "John Doe",
        "age": 45
      },
      "referringDoctor": {
        "name": "Dr. Sarah Smith",
        "specialty": "General Practice"
      },
      "reason": "Patient requires cardiology consultation...",
      "diagnosis": "Suspected angina pectoris",
      "hasAppointment": false
    }
  ],
  "pagination": {...},
  "summary": {
    "pending": 5,
    "urgent": 2,
    "emergency": 0
  }
}
```

### 5. Target Doctor Accepts Referral
```http
PUT /api/v1/referrals/65c789.../accept
Authorization: Bearer {targetDoctorToken}

{
  "responseNotes": "I will review the case and see the patient at scheduled time."
}
```

**Response:**
```json
{
  "message": "Referral accepted successfully"
}
```

### 6. Target Doctor Completes Referral
```http
PUT /api/v1/referrals/65c789.../complete
Authorization: Bearer {targetDoctorToken}

{
  "feedback": "Patient evaluated. Diagnosis confirmed as stable angina. Started on additional medication. Recommend follow-up in 3 months.",
  "consultationCreated": true
}
```

**Response:**
```json
{
  "message": "Referral completed successfully"
}
```

## Referral Status Flow

```
pending → scheduled → accepted → in_progress → completed
   ↓          ↓           ↓
rejected   cancelled   cancelled
```

### Status Definitions
- **pending**: Referral created, waiting for appointment/response
- **scheduled**: Appointment booked for the referral
- **accepted**: Target doctor accepted the referral
- **in_progress**: Consultation is happening
- **completed**: Consultation done, feedback provided
- **rejected**: Target doctor rejected the referral
- **cancelled**: Cancelled by referring doctor or patient

## Validation Rules

### Business Rules
1. **Doctor Verification**
   - Referring doctor must have treated the patient
   - Target doctor must be verified and active
   - Specialty must match target doctor's specialty

2. **Document Verification**
   - Attached documents must belong to the patient
   - Maximum 10 documents per referral

3. **Referral Expiry**
   - Referrals expire after 90 days (configurable)
   - Expired referrals cannot be used for appointments

4. **Access Control**
   - Only referring doctor, target doctor, and patient can view referral
   - Only referring doctor can book appointments
   - Only target doctor can accept/reject/complete referral
   - Patient and referring doctor can cancel referral

5. **Status Transitions**
   - Cannot accept/reject already completed referrals
   - Cannot complete without appointment
   - Cannot book appointment twice

## Kafka Events

### referral.created
```javascript
{
  event: 'referral.created',
  referralId: '65c789...',
  referringDoctorId: '65a123...',
  targetDoctorId: '65b456...',
  patientId: '65d012...',
  urgency: 'urgent',
  specialty: 'Cardiology'
}
```

### referral.scheduled
```javascript
{
  event: 'referral.scheduled',
  referralId: '65c789...',
  appointmentId: '65e345...',
  appointmentDate: '2025-11-20',
  appointmentTime: '14:00'
}
```

### referral.accepted / rejected / completed / cancelled
```javascript
{
  event: 'referral.accepted',
  referralId: '65c789...',
  targetDoctorId: '65b456...'
}
```

## Inter-Service Communication

### User Service
- Get doctor information
- Get patient information
- Search specialists by specialty and location

### RDV Service
- Check doctor availability
- Create referral appointments
- Cancel appointments
- Check doctor-patient treatment history

### Medical Records Service
- Verify treatment history
- Get attached document details
- Link to consultations

## Database Indexes

```javascript
// Optimize common queries
referralSchema.index({ referringDoctorId: 1, referralDate: -1 });
referralSchema.index({ targetDoctorId: 1, status: 1 });
referralSchema.index({ patientId: 1, referralDate: -1 });
referralSchema.index({ status: 1, urgency: 1 });
referralSchema.index({ expiryDate: 1 });
```

## Configuration

### Environment Variables
```env
PORT=3005
MONGODB_URI=mongodb://localhost:27017/esante-referrals
KAFKA_BROKERS=localhost:9092
JWT_SECRET=your_jwt_secret
USER_SERVICE_URL=http://localhost:3002/api/v1/users
RDV_SERVICE_URL=http://localhost:3003/api/v1/rdv
MEDICAL_RECORDS_SERVICE_URL=http://localhost:3004/api/v1/medical
REFERRAL_EXPIRY_DAYS=90
```

## Running the Service

### Development
```bash
cd backend/services/referral-service
npm install
npm run dev
```

### Production
```bash
npm start
```

### Required Services
- MongoDB (port 27017)
- Kafka + Zookeeper (port 9092)
- User Service (port 3002)
- RDV Service (port 3003)
- Medical Records Service (port 3004)

## Error Handling

All endpoints return consistent error responses:

```json
{
  "message": "Error description"
}
```

### Common Error Codes
- **400**: Validation error or invalid request
- **401**: Unauthorized (missing/invalid token)
- **403**: Forbidden (insufficient permissions)
- **404**: Resource not found
- **500**: Internal server error

## Testing

### Manual Testing with Postman

1. **Create Referral**
   - Login as doctor
   - Create referral for a patient you've treated
   - Verify target doctor receives notification

2. **Search Specialists**
   - Search by specialty
   - Filter by location
   - Verify results

3. **Book Appointment**
   - Book appointment for referral
   - Verify status changes to "scheduled"
   - Check appointment created in RDV service

4. **Target Doctor Flow**
   - Login as target doctor
   - View received referrals
   - Accept referral
   - Complete after consultation

5. **Patient View**
   - Login as patient
   - View referrals
   - Verify details displayed correctly

6. **Statistics**
   - View referral statistics as doctor
   - Verify counts and top specialties

## Dependencies

```json
{
  "express": "^4.18.2",
  "mongoose": "^7.6.3",
  "joi": "^17.10.2",
  "axios": "^1.5.1",
  "dotenv": "^16.3.1",
  "cors": "^2.8.5",
  "helmet": "^7.0.0"
}
```

**Total Packages:** 271  
**Vulnerabilities:** 0

## Future Enhancements

1. **AI-Powered Specialist Matching**: Suggest best specialists based on patient condition
2. **Urgent Referral Priority**: Auto-escalate emergency referrals
3. **Referral Templates**: Pre-filled templates for common conditions
4. **Batch Referrals**: Refer multiple patients at once
5. **Specialist Response Time Tracking**: Monitor response times
6. **Referral Quality Metrics**: Track outcomes and satisfaction
7. **Insurance Integration**: Check specialist accepts patient insurance
8. **Second Opinion Workflow**: Request multiple specialist opinions
9. **Telemedicine Integration**: Virtual specialist consultations
10. **Automated Follow-up Reminders**: Remind referring doctors to close referrals

## Contributing

Follow the E-Santé coding style guide:
- ES6 modules (import/export)
- Simple error responses `{message: "..."}`
- Publish Kafka events for all major actions
- Use shared middleware (auth, errorHandler, requestLogger)
- Validate all inputs with Joi
- Use async/await for async operations
- Document complex business logic

---

**Service:** Referral Service  
**Port:** 3005  
**Status:** ✅ Production Ready  
**Version:** 1.0.0
