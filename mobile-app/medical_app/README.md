# Medical App

## New Features

### Dossier Medical (Medical Records)

The app now includes a complete system for patients to manage their
medical records:

1. **Patient Requirements**: Patients must upload their medical files
   before they can schedule appointments.

2. **File Types Supported**:

   - Images (JPG, JPEG, PNG)
   - PDF documents

3. **Features**:

   - Upload, view, and manage medical files
   - Add descriptions to files
   - Delete individual files
   - Access medical records through patient profile

4. **Architecture**:

   - Follows clean architecture with Domain, Data, and Presentation
     layers
   - Uses BLoC pattern for state management
   - Integrates with the MongoDB database for storing file metadata
   - Files are physically stored on the server with paths saved in the
     database

5. **Server-Side Implementation**:

   - RESTful API endpoints in Express.js server (medical-app-mailer)
   - Multer middleware for file uploads
   - Secure storage system with patient-specific directories

6. **Integration Points**:
   - Profile screen for accessing medical records
   - Appointment scheduling (prevents scheduling without medical
     records)

## Getting Started

### Dossier Medical Setup

1. Make sure the Express server (medical-app-mailer) is running to
   handle file uploads
2. Verify MongoDB connection for storing dossier medical metadata
3. Ensure proper permissions are set for file uploads

### Using the Feature

As a patient:

1. Go to your profile
2. Tap on "Gérer mon dossier médical"
3. Upload your medical files
4. Once files are uploaded, you can schedule appointments

As a doctor:

1. Access patient profiles to view their medical files

A few resources to get you started if this is your first Flutter
project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers
tutorials, samples, guidance on mobile development, and a full API
reference.
