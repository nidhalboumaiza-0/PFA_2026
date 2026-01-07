import express from 'express';
import {
  createConsultation,
  getConsultationById,
  updateConsultation,
  getConsultationFullDetails,
  getPatientTimeline,
  searchPatientHistory,
  getDoctorConsultations,
  getMyMedicalHistory,
  getConsultationStatistics
} from '../controllers/consultationController.js';
import {
  createPrescription,
  getPrescriptionById,
  updatePrescription,
  lockPrescription,
  getPrescriptionHistory,
  getPatientPrescriptions,
  getActivePrescriptions,
  getMyPrescriptions
} from '../controllers/prescriptionController.js';
import {
  uploadDocument,
  getDocumentById,
  getPatientDocuments,
  getConsultationDocuments,
  getMyDocuments,
  updateDocument,
  deleteDocument,
  downloadDocument,
  updateDocumentSharing,
  getDocumentStatistics
} from '../controllers/documentController.js';
import {
  getDossierMedical,
  addFileToDossier,
  addFilesToDossier,
  deleteFile,
  updateFileDescription,
  getPatientMedicalHistory
} from '../controllers/dossierMedicalController.js';
import { getAdminStats } from '../controllers/adminController.js';
import { auth, authorize } from '../../../../shared/index.js';
import { uploadMiddleware, handleMulterError } from '../config/multerDocument.js';
import {
  validateCreateConsultation,
  validateUpdateConsultation,
  validateTimelineQuery,
  validateSearchQuery,
  validateConsultationHistoryQuery
} from '../validators/consultationValidator.js';
import {
  validateCreatePrescription,
  validateUpdatePrescription,
  validatePrescriptionQuery,
  validateMyPrescriptionsQuery
} from '../validators/prescriptionValidator.js';
import {
  validateUploadDocument,
  validateUpdateDocument,
  validateUpdateSharing,
  validateGetDocumentsQuery
} from '../validators/documentValidator.js';

const router = express.Router();

// ============================
// ADMIN ROUTES
// ============================

// Get admin statistics for medical records
router.get(
  '/admin/stats',
  auth,
  authorize('admin'),
  getAdminStats
);

// ============================
// DOCTOR ROUTES
// ============================

// Create consultation
router.post(
  '/consultations',
  auth,
  authorize('doctor'),
  validateCreateConsultation,
  createConsultation
);

// Update consultation
router.put(
  '/consultations/:consultationId',
  auth,
  authorize('doctor'),
  validateUpdateConsultation,
  updateConsultation
);

// Get consultation full details (doctor view)
router.get(
  '/consultations/:consultationId/full',
  auth,
  authorize('doctor'),
  getConsultationFullDetails
);

// Get patient medical timeline
router.get(
  '/patients/:patientId/timeline',
  auth,
  authorize('doctor'),
  validateTimelineQuery,
  getPatientTimeline
);

// Search patient history
router.get(
  '/patients/:patientId/search',
  auth,
  authorize('doctor'),
  validateSearchQuery,
  searchPatientHistory
);

// Get doctor's consultation history
router.get(
  '/doctors/my-consultations',
  auth,
  authorize('doctor'),
  validateConsultationHistoryQuery,
  getDoctorConsultations
);

// Get consultation statistics
router.get(
  '/statistics/consultations',
  auth,
  authorize('doctor'),
  getConsultationStatistics
);

// Doctor: Get patient's full medical history (requires appointment relationship)
// Includes shared documents, consultations from all doctors, prescriptions
router.get(
  '/patient-history/:patientId',
  auth,
  authorize('doctor'),
  getPatientMedicalHistory
);

// ============================
// PATIENT ROUTES
// ============================

// Patient view their medical history
router.get(
  '/patients/my-history',
  auth,
  authorize('patient'),
  getMyMedicalHistory
);

// Patient view their prescriptions
router.get(
  '/patients/my-prescriptions',
  auth,
  authorize('patient'),
  validateMyPrescriptionsQuery,
  getMyPrescriptions
);

// ============================
// PRESCRIPTION ROUTES (DOCTOR)
// ============================

// Create prescription
router.post(
  '/prescriptions',
  auth,
  authorize('doctor'),
  validateCreatePrescription,
  createPrescription
);

// Update prescription
router.put(
  '/prescriptions/:prescriptionId',
  auth,
  authorize('doctor'),
  validateUpdatePrescription,
  updatePrescription
);

// Lock prescription manually
router.post(
  '/prescriptions/:prescriptionId/lock',
  auth,
  authorize('doctor'),
  lockPrescription
);

// Get prescription modification history
router.get(
  '/prescriptions/:prescriptionId/history',
  auth,
  authorize('doctor'),
  getPrescriptionHistory
);

// Get patient's prescriptions
router.get(
  '/patients/:patientId/prescriptions',
  auth,
  authorize('doctor'),
  validatePrescriptionQuery,
  getPatientPrescriptions
);

// Get active prescriptions for patient
router.get(
  '/patients/:patientId/active-prescriptions',
  auth,
  authorize('doctor'),
  getActivePrescriptions
);

// ============================
// SHARED ROUTES
// ============================

// Get consultation by ID (both doctor & patient)
router.get(
  '/consultations/:consultationId',
  auth,
  getConsultationById
);

// Get prescription by ID (both doctor & patient)
router.get(
  '/prescriptions/:prescriptionId',
  auth,
  getPrescriptionById
);

// ============================
// DOCUMENT ROUTES (DOCTOR)
// ============================

// Upload document
router.post(
  '/documents/upload',
  auth,
  authorize('doctor', 'patient'),
  uploadMiddleware.single('file'),
  handleMulterError,
  validateUploadDocument,
  uploadDocument
);

// Get patient's documents
router.get(
  '/documents/patient/:patientId',
  auth,
  authorize('doctor'),
  validateGetDocumentsQuery,
  getPatientDocuments
);

// Update document metadata
router.put(
  '/documents/:documentId',
  auth,
  validateUpdateDocument,
  updateDocument
);

// Delete document
router.delete(
  '/documents/:documentId',
  auth,
  deleteDocument
);

// Get document statistics
router.get(
  '/documents/statistics',
  auth,
  getDocumentStatistics
);

// ============================
// DOCUMENT ROUTES (PATIENT)
// ============================

// Get my documents
router.get(
  '/documents/my-documents',
  auth,
  authorize('patient'),
  validateGetDocumentsQuery,
  getMyDocuments
);

// Update document sharing
router.put(
  '/documents/:documentId/sharing',
  auth,
  authorize('patient'),
  validateUpdateSharing,
  updateDocumentSharing
);

// ============================
// DOCUMENT ROUTES (SHARED)
// ============================

// Get document by ID
router.get(
  '/documents/:documentId',
  auth,
  getDocumentById
);

// Download document
router.get(
  '/documents/:documentId/download',
  auth,
  downloadDocument
);

// Get consultation documents
router.get(
  '/consultations/:consultationId/documents',
  auth,
  getConsultationDocuments
);

// ============================
// DOSSIER MEDICAL ROUTES
// ============================

// Get Dossier Medical
router.get(
  '/dossier-medical/:patientId',
  auth,
  getDossierMedical
);

// Add File to Dossier
router.post(
  '/dossier-medical/:patientId/files',
  auth,
  uploadMiddleware.single('file'),
  handleMulterError,
  addFileToDossier
);

// Add Multiple Files to Dossier
router.post(
  '/dossier-medical/:patientId/multiple-files',
  auth,
  uploadMiddleware.array('files'),
  handleMulterError,
  addFilesToDossier
);

// Delete File from Dossier
router.delete(
  '/dossier-medical/:patientId/files/:fileId',
  auth,
  deleteFile
);

// Update File Description
router.patch(
  '/dossier-medical/:patientId/files/:fileId',
  auth,
  updateFileDescription
);

export default router;
