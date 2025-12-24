# Medical App Mailer

This is the backend service for the Medical App project.

## Dossier Medical API

The Dossier Medical API allows you to manage patient medical files.

### Endpoints

#### Get a Patient's Medical Record

```
GET /api/v1/dossier-medical/:patientId
```

**Response**

```json
{
  "status": "success",
  "data": {
    "dossier": {
      "_id": "60d21b4667d0d8992e610c85",
      "patientId": "firebase-patient-id",
      "files": [
        {
          "_id": "60d21b4667d0d8992e610c86",
          "filename": "2023-06-20T10-30-45.123Z-blood-test.pdf",
          "originalName": "blood-test.pdf",
          "path": "uploads/patient-files/firebase-patient-id/2023-06-20T10-30-45.123Z-blood-test.pdf",
          "mimetype": "application/pdf",
          "size": 123456,
          "description": "Blood test results from May 2023",
          "createdAt": "2023-06-20T10:30:45.123Z"
        }
      ],
      "createdAt": "2023-06-20T10:30:45.123Z",
      "updatedAt": "2023-06-20T10:30:45.123Z"
    }
  }
}
```

#### Add a Single File to a Patient's Medical Record

```
POST /api/v1/dossier-medical/:patientId/files
```

**Request**

- Format: `multipart/form-data`
- Fields:
  - `file`: The file to upload (required)
  - `description`: Description of the file (optional)

**Response**

```json
{
  "status": "success",
  "data": {
    "dossier": {
      "_id": "60d21b4667d0d8992e610c85",
      "patientId": "firebase-patient-id",
      "files": [
        {
          "_id": "60d21b4667d0d8992e610c86",
          "filename": "2023-06-20T10-30-45.123Z-blood-test.pdf",
          "originalName": "blood-test.pdf",
          "path": "uploads/patient-files/firebase-patient-id/2023-06-20T10-30-45.123Z-blood-test.pdf",
          "mimetype": "application/pdf",
          "size": 123456,
          "description": "Blood test results from May 2023",
          "createdAt": "2023-06-20T10:30:45.123Z"
        }
      ],
      "createdAt": "2023-06-20T10:30:45.123Z",
      "updatedAt": "2023-06-20T10:30:45.123Z"
    }
  }
}
```

#### Add Multiple Files to a Patient's Medical Record

```
POST /api/v1/dossier-medical/:patientId/multiple-files
```

**Request**

- Format: `multipart/form-data`
- Fields:
  - `files`: The files to upload (required, up to 10 files)
  - `descriptions`: JSON object mapping file IDs to descriptions
    (optional) Example:
    `{"file1": "X-ray report", "file2": "MRI scan"}`

**Response**

```json
{
  "status": "success",
  "data": {
    "dossier": {
      "_id": "60d21b4667d0d8992e610c85",
      "patientId": "firebase-patient-id",
      "files": [
        {
          "_id": "60d21b4667d0d8992e610c86",
          "filename": "2023-06-20T10-30-45.123Z-blood-test.pdf",
          "originalName": "blood-test.pdf",
          "path": "uploads/patient-files/firebase-patient-id/2023-06-20T10-30-45.123Z-blood-test.pdf",
          "mimetype": "application/pdf",
          "size": 123456,
          "description": "Blood test results from May 2023",
          "createdAt": "2023-06-20T10:30:45.123Z"
        },
        {
          "_id": "60d21b4667d0d8992e610c87",
          "filename": "2023-06-20T10-31-45.123Z-xray.jpg",
          "originalName": "xray.jpg",
          "path": "uploads/patient-files/firebase-patient-id/2023-06-20T10-31-45.123Z-xray.jpg",
          "mimetype": "image/jpeg",
          "size": 234567,
          "description": "Chest X-ray from June 2023",
          "createdAt": "2023-06-20T10:31:45.123Z"
        }
      ],
      "createdAt": "2023-06-20T10:30:45.123Z",
      "updatedAt": "2023-06-20T10:31:45.123Z"
    }
  }
}
```

#### Update a File Description

```
PATCH /api/v1/dossier-medical/:patientId/files/:fileId
```

**Request**

```json
{
  "description": "Updated description for the file"
}
```

**Response**

```json
{
  "status": "success",
  "data": {
    "file": {
      "_id": "60d21b4667d0d8992e610c86",
      "filename": "2023-06-20T10-30-45.123Z-blood-test.pdf",
      "originalName": "blood-test.pdf",
      "path": "uploads/patient-files/firebase-patient-id/2023-06-20T10-30-45.123Z-blood-test.pdf",
      "mimetype": "application/pdf",
      "size": 123456,
      "description": "Updated description for the file",
      "createdAt": "2023-06-20T10:30:45.123Z"
    }
  }
}
```

#### Delete a File

```
DELETE /api/v1/dossier-medical/:patientId/files/:fileId
```

**Response**

```json
{
  "status": "success",
  "message": "Fichier supprimé avec succès"
}
```

### File Access

Files can be accessed directly via their URL:

```
GET /uploads/patient-files/:patientId/:filename
```

### Supported File Types

- Images: JPEG, PNG, JPG
- Documents: PDF

### File Size Limit

Maximum file size: 10MB per file

## Authentication

All endpoints require authentication. Include the JWT token in the
Authorization header:

```
Authorization: Bearer your-token-here
```

# Medical App API - Appointment System

## Appointment Duration System

The appointment system now uses the doctor's `appointmentDuration` setting to automatically calculate appointment end times.

### How it works:

1. The doctor sets their `appointmentDuration` in their profile (default is 30 minutes)
2. When a patient creates an appointment, they only need to provide:
   - `startDate`: The desired appointment start time
   - `medecinId`: The ID of the doctor
   - `serviceName`: The service being requested
   - `motif` (optional): Reason for the appointment
   - `symptoms` (optional): Array of symptoms

3. The system automatically calculates the `endDate` by adding the doctor's `appointmentDuration` to the `startDate`

### Example API Request:

```json
POST /api/v1/appointments/createAppointment
{
  "startDate": "2023-11-10T14:30:00.000Z",
  "serviceName": "Consultation générale",
  "medecinId": "6015f3f5c8b4a43f28a7f4b1",
  "motif": "Maux de tête persistants",
  "symptoms": ["Maux de tête", "Fièvre"]
}
```

### Example API Response:

```json
{
  "status": "success",
  "data": {
    "appointment": {
      "_id": "6015f5c5c8b4a43f28a7f4b3",
      "startDate": "2023-11-10T14:30:00.000Z",
      "endDate": "2023-11-10T15:00:00.000Z",
      "serviceName": "Consultation générale",
      "patient": "6015f2a5c8b4a43f28a7f4b0",
      "medecin": "6015f3f5c8b4a43f28a7f4b1",
      "status": "En attente",
      "motif": "Maux de tête persistants",
      "symptoms": ["Maux de tête", "Fièvre"],
      "isRated": false,
      "hasPrescription": false,
      "createdAt": "2023-11-05T10:15:00.000Z"
    }
  }
}
```

## Setting Doctor's Appointment Duration

Doctors can set their appointment duration through the user profile update endpoint:

```json
PATCH /api/v1/users/updateMe
{
  "appointmentDuration": 45
}
```

This will set the doctor's appointment duration to 45 minutes. All future appointments will be scheduled for 45-minute slots.
