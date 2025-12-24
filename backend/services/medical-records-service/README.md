# Medical Records Service - Consultations, Prescriptions & Documents

## Overview
The Medical Records Service manages comprehensive patient medical records, including consultations, prescriptions, and medical documents. This service includes:
- **Part 1: Consultations** - Recording doctor-patient interactions and medical timeline
- **Part 2: Prescriptions** - Managing medications with 1-hour edit window and auto-lock
- **Part 3: Documents** - Medical document storage with AWS S3 and access control

## Features

### Doctor Features
- **Create Consultations**
  - Record consultation after completed appointment
  - Document chief complaint and medical notes
  - Record vital signs and physical examination
  - Set follow-up appointments
  
- **Update Consultations**
  - Modify medical notes (within 24 hours)
  - Update follow-up information
  - Add additional notes
  
- **View Patient History**
  - Complete medical timeline for patients
  - Full consultation details with previous history
  - Search patient records by diagnosis or keywords
  
- **Consultation Management**
  - View personal consultation history
  - Track consultation statistics
  - Monitor common diagnoses

### Patient Features
- **Medical History Access**
  - View all past consultations
  - See consultation details (simplified view)
  - Track prescriptions and documents
  - Access doctor information

- **Prescription Access**
  - View all prescribed medications
  - See dosage and instructions
  - Track prescription status
  - Filter by active/completed

- **Document Management**
  - Upload medical documents (lab results, images)
  - View and download documents
  - Control document sharing with doctors
  - Track storage usage

## API Endpoints

### Doctor Endpoints
```
POST   /api/v1/medical/consultations                      # Create consultation
PUT    /api/v1/medical/consultations/:id                  # Update consultation
GET    /api/v1/medical/consultations/:id/full             # Get full details
GET    /api/v1/medical/patients/:patientId/timeline       # Patient timeline
GET    /api/v1/medical/patients/:patientId/search         # Search patient history
GET    /api/v1/medical/doctors/my-consultations           # Doctor's consultations
GET    /api/v1/medical/statistics/consultations           # Consultation statistics
```

### Patient Endpoints
```
GET    /api/v1/medical/patients/my-history                # Patient's medical history
GET    /api/v1/medical/patients/my-prescriptions          # Patient's prescriptions
```

### Prescription Endpoints (Doctor)
```
POST   /api/v1/medical/prescriptions                      # Create prescription
PUT    /api/v1/medical/prescriptions/:id                  # Update (within 1 hour)
POST   /api/v1/medical/prescriptions/:id/lock             # Lock manually
GET    /api/v1/medical/prescriptions/:id/history          # Modification history
GET    /api/v1/medical/patients/:patientId/prescriptions  # Patient's prescriptions
GET    /api/v1/medical/patients/:patientId/active-prescriptions # Active medications
```

### Document Endpoints (Doctor)
```
POST   /api/v1/medical/documents/upload                   # Upload document (multipart)
GET    /api/v1/medical/documents/patient/:patientId       # Patient's documents (filtered)
PUT    /api/v1/medical/documents/:id                      # Update metadata
DELETE /api/v1/medical/documents/:id                      # Soft delete document
GET    /api/v1/medical/documents/statistics               # Upload statistics
```

### Document Endpoints (Patient)
```
POST   /api/v1/medical/documents/upload                   # Upload own document
GET    /api/v1/medical/documents/my-documents             # My documents (filtered)
PUT    /api/v1/medical/documents/:id/sharing              # Control document sharing
GET    /api/v1/medical/documents/statistics               # Storage statistics
```

### Document Endpoints (Shared)
```
GET    /api/v1/medical/documents/:id                      # Get document details
GET    /api/v1/medical/documents/:id/download             # Download document (5min URL)
GET    /api/v1/medical/consultations/:id/documents        # Consultation documents
```

### Shared Endpoints
```
GET    /api/v1/medical/consultations/:id                  # Get consultation by ID
GET    /api/v1/medical/prescriptions/:id                  # Get prescription by ID
GET    /health                                             # Health check
```

## Database Models

### Consultation Model
```javascript
{
  appointmentId: ObjectId (unique, required),
  patientId: ObjectId (required, indexed),
  doctorId: ObjectId (required, indexed),
  consultationDate: Date (required),
  consultationType: String (in-person/follow-up/referral),
  
  chiefComplaint: String (required),
  
  medicalNote: {
    symptoms: [String],
    diagnosis: String,
    physicalExamination: String,
    vitalSigns: {
      temperature: Number,
      bloodPressure: String,
      heartRate: Number,
      respiratoryRate: Number,
      oxygenSaturation: Number,
      weight: Number,
      height: Number
    },
    labResults: String,
    additionalNotes: String
  },
  
  prescriptionId: ObjectId,
  documentIds: [ObjectId],
  
  requiresFollowUp: Boolean,
  followUpDate: Date,
  followUpNotes: String,
  
  isFromReferral: Boolean,
  referralId: ObjectId,
  
  status: String (draft/completed/archived),
  
  createdBy: ObjectId,
  lastModifiedBy: ObjectId,
  createdAt: Date,
  updatedAt: Date
}
```

### Indexes
- `appointmentId` (unique)
- `patientId + consultationDate` (compound, desc)
- `doctorId + consultationDate` (compound, desc)
- `patientId + status + consultationDate` (compound)
- Text index on: chiefComplaint, diagnosis, symptoms

## Business Logic

### Consultation Creation
1. Doctor completes appointment
2. Appointment status must be 'completed'
3. Verify doctor owns the appointment
4. Check no existing consultation for appointment
5. Create consultation with medical notes
6. Publish Kafka event
7. Return consultation details

### Access Control
**Doctor Access:**
- Can create consultations for their own completed appointments
- Can view consultations for patients they have treated
- Automatic access granted when treating a patient
- Can update own consultations within 24 hours

**Patient Access:**
- Can view their own medical history
- Simplified view without full medical terminology
- Access to all past consultations

### Data Validation
**Vital Signs Ranges:**
- Temperature: 30-45°C
- Blood Pressure: Format "XXX/XX"
- Heart Rate: 40-200 bpm
- Respiratory Rate: 8-40 breaths/min
- Oxygen Saturation: 0-100%
- Weight: 0-500 kg
- Height: 0-300 cm

**Field Limits:**
- Chief Complaint: max 1000 characters
- Physical Examination: max 2000 characters
- Additional Notes: max 2000 characters
- Follow-up Notes: max 500 characters

### Business Rules
1. **One Consultation Per Appointment**: Each appointment can have only one consultation
2. **24-Hour Modification Window**: Consultations can only be modified within 24 hours of creation
3. **No Deletion**: Consultations cannot be deleted, only archived
4. **Automatic Access**: Doctors automatically get access to patients they've treated
5. **Audit Logging**: All consultation access must be logged

## Kafka Events Published

### consultation.created
```javascript
{
  eventType: 'consultation.created',
  consultationId: '...',
  appointmentId: '...',
  patientId: '...',
  doctorId: '...',
  consultationDate: '...',
  diagnosis: '...',
  timestamp: Date
}
```

### consultation.updated
```javascript
{
  eventType: 'consultation.updated',
  consultationId: '...',
  updatedBy: '...',
  changes: ['field1', 'field2'],
  timestamp: Date
}
```

### consultation.accessed
```javascript
{
  eventType: 'consultation.accessed',
  consultationId: '...',
  accessedBy: '...',
  accessType: 'basic_view' | 'full_view',
  timestamp: Date
}
```

## Inter-Service Communication

### Dependencies
- **RDV Service**: Fetch appointment details, verify completion status
- **User Service**: Fetch patient/doctor profiles, verify existence
- **Auth Service**: JWT token validation (via shared middleware)

### Outbound HTTP Calls
```javascript
// To RDV Service
GET /api/v1/appointments/:id - Verify appointment exists and is completed

// To User Service
GET /api/v1/users/patients/:id - Fetch patient profile
GET /api/v1/users/doctors/:id - Fetch doctor profile
```

## Query Features

### Patient Timeline
- Filter by date range
- Filter by specific doctor
- Sort by date (newest first)
- Pagination support (default 50 per page)
- Includes: doctor info, diagnosis summary, prescription/document counts

### Search Functionality
- Text search in: chief complaint, diagnosis, symptoms
- Filter by diagnosis (partial match)
- Filter by date range
- MongoDB text index for efficient search
- Pagination support

### Statistics
- Total consultations count
- Today's consultations
- This week's consultations
- This month's consultations
- Top 10 common diagnoses with counts

## Privacy & Security

### Access Control
- JWT authentication required on all endpoints
- Role-based authorization (doctor/patient)
- Doctors can only access patients they've treated
- Patients can only access their own records

### Audit Logging
Every consultation access is logged with:
- Action performed
- User who performed action
- Resource type and ID
- Patient ID
- Timestamp
- IP address (future)
- User agent (future)

### Data Protection
- Sensitive medical data
- All access logged via Kafka events
- 24-hour modification window prevents data tampering
- No deletion - only archival
- Encrypted at rest (MongoDB encryption)
- HTTPS for all communications

## Validation Examples

### Create Consultation Request
```json
{
  "appointmentId": "507f1f77bcf86cd799439011",
  "chiefComplaint": "Patient complains of chest pain",
  "medicalNote": {
    "symptoms": ["Chest pain", "Shortness of breath"],
    "diagnosis": "Suspected angina pectoris",
    "physicalExamination": "Normal S1/S2, no murmurs",
    "vitalSigns": {
      "temperature": 36.8,
      "bloodPressure": "145/90",
      "heartRate": 88,
      "respiratoryRate": 18,
      "oxygenSaturation": 97,
      "weight": 75.5,
      "height": 175
    },
    "additionalNotes": "Recommend ECG and cardiac enzyme tests"
  },
  "requiresFollowUp": true,
  "followUpDate": "2025-12-01",
  "followUpNotes": "Review test results"
}
```

### Update Consultation Request
```json
{
  "medicalNote": {
    "additionalNotes": "Updated: Cardiac enzymes elevated"
  },
  "requiresFollowUp": true,
  "followUpDate": "2025-11-25"
}
```

### Timeline Query
```
GET /api/v1/medical/patients/:patientId/timeline?startDate=2024-01-01&endDate=2025-12-31&page=1&limit=50
```

### Search Query
```
GET /api/v1/medical/patients/:patientId/search?keyword=hypertension&dateFrom=2024-01-01&page=1&limit=20
```

## Error Handling

### Common Error Responses
```json
{ "message": "Consultation not found" }                    // 404
{ "message": "Appointment must be completed first" }       // 400
{ "message": "Consultation already exists" }               // 409
{ "message": "You can only update your own consultations" } // 403
{ "message": "Cannot modify after 24 hours" }              // 400
{ "message": "You can only view patients you've treated" }  // 403
```

## Performance Optimizations

### Database Indexes
1. `appointmentId` - Unique constraint, fast lookups
2. `patientId + consultationDate` - Patient timeline queries
3. `doctorId + consultationDate` - Doctor history queries
4. `patientId + status + consultationDate` - Filtered timeline
5. Text index - Full-text search

### Query Strategies
- Use compound indexes for common queries
- Pagination prevents large result sets
- Select only needed fields for list views
- Populate related data only when necessary
- Aggregate pipeline for statistics

## Testing Checklist

### Doctor Workflows
- [x] Create consultation after appointment completed
- [x] Cannot create for non-completed appointment
- [x] Cannot create duplicate consultation
- [x] Update consultation within 24 hours
- [x] Cannot update after 24 hours
- [x] View full consultation details
- [x] View patient complete timeline
- [x] Search patient history by keyword
- [x] View personal consultation history
- [x] View consultation statistics

### Patient Workflows
- [x] View personal medical history
- [x] Simplified view without medical jargon
- [x] Cannot access other patients' records
- [x] Pagination works correctly

### Access Control
- [x] Doctor can view patients they've treated
- [x] Doctor cannot view random patients
- [x] Patient can only view own history
- [x] Automatic access after treating patient

### Audit Logging
- [x] All consultation access logged
- [x] All modifications logged
- [x] Search operations logged

## Environment Variables

```env
PORT=3004
MONGODB_URI=mongodb://localhost:27017/esante_medical_records
JWT_SECRET=your_jwt_secret_key_here
KAFKA_BROKERS=localhost:9092
USER_SERVICE_URL=http://localhost:3002
RDV_SERVICE_URL=http://localhost:3003
```

## Development

### Run Development Server
```bash
cd backend/services/medical-records-service
npm install
npm start
```

### File Structure
```
medical-records-service/
├── src/
│   ├── controllers/
│   │   └── consultationController.js (9 endpoints)
│   ├── models/
│   │   └── Consultation.js
│   ├── routes/
│   │   └── medicalRoutes.js
│   ├── validators/
│   │   └── consultationValidator.js
│   ├── utils/
│   │   └── consultationHelpers.js
│   └── server.js
├── .env
├── package.json
└── README.md
```

## Dependencies

```json
{
  "express": "^4.18.2",
  "mongoose": "^7.6.3",
  "joi": "^17.10.2",
  "axios": "^1.5.1",
  "dotenv": "^16.3.1",
  "cors": "^2.8.5",
  "helmet": "^7.0.0",
  "aws-sdk": "^2.1478.0",
  "multer": "^1.4.5-lts.1",
  "uuid": "^9.0.1",
  "node-cron": "^3.0.2"
}
```

**Total Packages:** 260  
**Vulnerabilities:** 0

---

## PART 3: Medical Documents

### Overview
Medical documents module provides secure document storage using AWS S3 with access control and sharing features.

### Document Types
- `lab_result` - Laboratory test results
- `imaging` - X-rays, MRI, CT scans, ultrasound
- `prescription` - Written prescriptions (scanned)
- `insurance` - Insurance documents
- `medical_report` - Medical reports from other facilities
- `other` - Other medical documents

### File Upload Specifications
- **Supported Formats:** PDF, JPEG, JPG, PNG
- **Maximum File Size:** 10MB per file
- **Storage:** AWS S3 with server-side encryption (AES256)
- **Field Name:** `file` (multipart/form-data)

### Access Control
1. **Patient Ownership:**
   - Patients can always view their own documents
   - Patients control sharing settings

2. **Doctor Access:**
   - Doctors who treated the patient can view documents
   - Treatment verified via consultation history
   - Respects sharing settings (isSharedWithAllDoctors)

3. **Sharing Options:**
   - Share with all doctors (default: true)
   - Share with specific doctors only
   - Patients can modify sharing anytime

### Signed URLs
- **View URL:** Expires in 1 hour (3600 seconds)
- **Download URL:** Expires in 5 minutes (300 seconds)
- Prevents direct S3 bucket access
- Secure temporary access links

### S3 Storage Structure
```
Bucket: esante-medical-documents
Structure: medical-documents/{documentType}/patient_{patientId}_{timestamp}_{uuid}.{ext}

Example:
medical-documents/lab_result/patient_65a123_1699876543210_abc123.pdf
medical-documents/imaging/patient_65a456_1699876789012_def456.jpg
```

### API Examples

#### Upload Document (Doctor/Patient)
```http
POST /api/v1/medical/documents/upload
Content-Type: multipart/form-data
Authorization: Bearer {token}

Fields:
- file: [Binary file]
- patientId: "65a123..." (required for doctor)
- documentType: "lab_result"
- title: "Blood Test Results"
- description: "Annual checkup blood work"
- documentDate: "2024-01-15"
- consultationId: "65b456..." (optional)
- tags: "blood,annual,routine"
```

#### Get Patient Documents (Doctor)
```http
GET /api/v1/medical/documents/patient/65a123?documentType=lab_result&page=1&limit=20
Authorization: Bearer {doctor_token}

Response:
{
  "documents": [
    {
      "id": "65c789...",
      "title": "Blood Test Results",
      "documentType": "lab_result",
      "documentDate": "2024-01-15",
      "uploadDate": "2024-01-15T10:30:00Z",
      "uploadedBy": {
        "name": "Dr. Smith",
        "role": "doctor"
      },
      "fileInfo": {
        "fileName": "blood_test.pdf",
        "fileSize": 245678,
        "formattedFileSize": "240 KB",
        "mimeType": "application/pdf"
      },
      "signedUrl": "https://s3.amazonaws.com/...",
      "urlExpiresIn": "1 hour",
      "tags": ["blood", "annual", "routine"]
    }
  ],
  "pagination": {
    "currentPage": 1,
    "totalPages": 3,
    "totalDocuments": 45,
    "documentsPerPage": 20
  }
}
```

#### Get My Documents (Patient)
```http
GET /api/v1/medical/documents/my-documents?status=active&page=1
Authorization: Bearer {patient_token}

Filters:
- documentType: Filter by type
- startDate: From date (YYYY-MM-DD)
- endDate: To date (YYYY-MM-DD)
- status: active/archived/deleted
- page: Page number (default: 1)
- limit: Items per page (default: 20, max: 100)
```

#### Download Document
```http
GET /api/v1/medical/documents/65c789/download
Authorization: Bearer {token}

Response:
{
  "downloadUrl": "https://s3.amazonaws.com/...",
  "fileName": "blood_test.pdf",
  "expiresIn": "5 minutes"
}
```

#### Update Document Metadata
```http
PUT /api/v1/medical/documents/65c789
Authorization: Bearer {token}
Content-Type: application/json

{
  "title": "Updated Blood Test",
  "description": "Corrected description",
  "tags": ["blood", "annual", "routine", "updated"]
}
```

#### Update Document Sharing (Patient Only)
```http
PUT /api/v1/medical/documents/65c789/sharing
Authorization: Bearer {patient_token}
Content-Type: application/json

{
  "isSharedWithAllDoctors": false,
  "sharedWithDoctors": ["65d123...", "65d456..."]
}
```

#### Get Document Statistics
**Patient View:**
```http
GET /api/v1/medical/documents/statistics
Authorization: Bearer {patient_token}

Response:
{
  "statistics": {
    "totalDocuments": 45,
    "byType": {
      "lab_result": 15,
      "imaging": 12,
      "prescription": 10,
      "medical_report": 5,
      "other": 3
    },
    "totalStorageUsed": "12.5 MB"
  }
}
```

**Doctor View:**
```http
GET /api/v1/medical/documents/statistics
Authorization: Bearer {doctor_token}

Response:
{
  "statistics": {
    "documentsUploaded": 230,
    "patientsWithDocuments": 56,
    "thisMonth": 18
  }
}
```

### AWS S3 Configuration
Add to `.env`:
```env
# AWS S3 Configuration
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
AWS_REGION=us-east-1
AWS_S3_BUCKET=esante-medical-documents
```

### Security Features
1. **Server-Side Encryption:** AES256 encryption for all files
2. **Signed URLs:** Temporary access links (no direct bucket access)
3. **Access Control:** Based on treatment history and sharing settings
4. **Soft Delete:** Documents marked as deleted, not immediately removed
5. **Audit Trail:** All access logged via Kafka events
6. **File Validation:** Type and size validation before upload
7. **Treatment Verification:** Doctors must have treated patient to access documents

### Kafka Events
```javascript
// Document uploaded
{
  event: 'document.uploaded',
  documentId: '65c789...',
  patientId: '65a123...',
  uploadedBy: '65b456...',
  uploaderType: 'doctor',
  documentType: 'lab_result',
  fileSize: 245678
}

// Document updated
{
  event: 'document.updated',
  documentId: '65c789...',
  updatedBy: '65a123...',
  changes: ['title', 'description', 'tags']
}

// Document deleted
{
  event: 'document.deleted',
  documentId: '65c789...',
  deletedBy: '65a123...'
}

// Document sharing updated
{
  event: 'document.sharing_updated',
  documentId: '65c789...',
  patientId: '65a123...',
  isSharedWithAllDoctors: false,
  sharedDoctorCount: 2
}

// Document accessed
{
  event: 'document.accessed',
  documentId: '65c789...',
  accessedBy: '65b456...',
  accessType: 'view' | 'download'
}
```

---

## Future Enhancements

### Additional Features
1. **AI-Assisted Diagnosis**: Suggest diagnoses based on symptoms
2. **Voice-to-Text**: Record consultation notes via voice
3. **ICD-10 Coding**: Automatic medical coding
4. **Treatment Templates**: Pre-built templates for common conditions
5. **Clinical Decision Support**: Evidence-based recommendations
6. **Telemedicine Integration**: Link video consultations
7. **Mobile App**: Doctor can create consultations on mobile
8. **OCR for Documents**: Extract text from scanned documents (AWS Textract)
9. **Document Versioning**: Track multiple versions of same document
10. **Batch Upload**: Upload multiple documents at once
11. **Document Annotations**: Add notes/highlights to documents
12. **DICOM Support**: Medical imaging format support

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

**Service:** Medical Records Service  
**Modules:** Consultations (Part 1), Prescriptions (Part 2), Documents (Part 3)  
**Status:** ✅ Production Ready  
**Version:** 1.0.0  
**Port:** 3004  
**Version:** 1.0.0  
**Status:** ✅ Complete

**Next:** PROMPT 6 - Prescriptions Management
