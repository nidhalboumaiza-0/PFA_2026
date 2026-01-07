import MedicalDocument from '../models/MedicalDocument.js';
import Consultation from '../models/Consultation.js';
import Prescription from '../models/Prescription.js';
import { kafkaProducer, TOPICS, createEvent, sendError, sendSuccess, getConfig } from '../../../../shared/index.js';
import {
    uploadDocumentToS3,
    getSignedUrl,
    deleteDocumentFromS3
} from '../services/s3DocumentService.js';
import { validateFile, getFileExtension } from '../config/multerDocument.js';
import { formatDocumentList } from '../utils/documentHelpers.js';

// Helper to check if doctor has appointment relationship with patient
const checkDoctorPatientRelationship = async (doctorId, patientId) => {
    // First check if doctor has any completed consultation with this patient
    const consultation = await Consultation.findOne({
        doctorId,
        patientId,
        status: { $in: ['completed', 'archived'] }
    });
    
    if (consultation) return true;
    
    // If no completed consultation, check if there's a confirmed/scheduled appointment
    // via rdv-service API call
    try {
        const rdvServiceUrl = getConfig('RDV_SERVICE_URL', 'http://rdv-service:3003');
        const response = await fetch(
            `${rdvServiceUrl}/api/v1/appointments/check-relationship?doctorId=${doctorId}&patientId=${patientId}`
        );
        
        if (response.ok) {
            const data = await response.json();
            return data.hasAppointment === true;
        }
    } catch (error) {
        console.error('Failed to check appointment relationship:', error.message);
    }
    
    return false;
};

/**
 * Get Dossier Medical
 * GET /api/v1/medical/dossier-medical/:patientId
 */
export const getDossierMedical = async (req, res, next) => {
    try {
        const { profileId, role } = req.user;
        const { patientId } = req.params;

        // Verify access
        if (role === 'patient' && profileId.toString() !== patientId.toString()) {
            return sendError(res, 403, 'FORBIDDEN',
                'You can only view your own medical dossier.');
        }

        // Fetch all components of the dossier
        const [documents, consultations, prescriptions] = await Promise.all([
            MedicalDocument.find({
                patientId,
                status: { $in: ['active', 'archived'] }
            }).sort({ uploadDate: -1 }),
            Consultation.find({
                patientId,
                status: { $in: ['completed', 'archived'] }
            }).sort({ consultationDate: -1 }),
            Prescription.find({
                patientId,
                status: { $in: ['active', 'completed'] }
            }).sort({ prescribedDate: -1 })
        ]);

        // Format documents with signed URLs
        const formattedDocuments = await formatDocumentList(documents, getSignedUrl);

        // Construct the dossier object
        const dossier = {
            id: patientId, // Using patientId as dossier ID since it's 1-to-1
            patientId,
            files: formattedDocuments,
            consultations,
            prescriptions
        };

        res.status(200).json({
            data: {
                dossier
            }
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Add File to Dossier
 * POST /api/v1/medical/dossier-medical/:patientId/files
 */
export const addFileToDossier = async (req, res, next) => {
    try {
        const { profileId: userId, role } = req.user;
        const { patientId } = req.params;
        const { description } = req.body;

        // Verify access
        if (role === 'patient' && userId.toString() !== patientId.toString()) {
            return sendError(res, 403, 'FORBIDDEN',
                'You can only add files to your own dossier.');
        }

        if (!req.file) {
            return sendError(res, 400, 'NO_FILE',
                'No file provided. Please select a file to upload.');
        }

        validateFile(req.file);

        // Upload to S3
        const { s3Key, s3Bucket, s3Url } = await uploadDocumentToS3(
            req.file.buffer,
            req.file.originalname,
            req.file.mimetype,
            patientId,
            'medical_report' // Default type
        );

        // Create document record
        const document = await MedicalDocument.create({
            patientId,
            uploadedBy: userId,
            uploaderType: role,
            documentType: 'medical_report',
            title: req.file.originalname,
            description: description || '',
            fileName: req.file.originalname,
            fileSize: req.file.size,
            mimeType: req.file.mimetype,
            fileExtension: getFileExtension(req.file.mimetype),
            s3Key,
            s3Bucket,
            s3Url,
            uploadDate: new Date(),
            status: 'active'
        });

        // Return updated dossier
        // We can just call getDossierMedical logic or return the new dossier state
        // For efficiency, let's just return the full dossier as the app expects it
        // But calling getDossierMedical internal logic is better to ensure consistency

        // Re-fetch dossier
        const [documents, consultations, prescriptions] = await Promise.all([
            MedicalDocument.find({
                patientId,
                status: { $in: ['active', 'archived'] }
            }).sort({ uploadDate: -1 }),
            Consultation.find({
                patientId,
                status: { $in: ['completed', 'archived'] }
            }).sort({ consultationDate: -1 }),
            Prescription.find({
                patientId,
                status: { $in: ['active', 'completed'] }
            }).sort({ prescribedDate: -1 })
        ]);

        const formattedDocuments = await formatDocumentList(documents, getSignedUrl);

        const dossier = {
            id: patientId,
            patientId,
            files: formattedDocuments,
            consultations,
            prescriptions
        };

        res.status(201).json({
            data: {
                dossier
            }
        });

    } catch (error) {
        next(error);
    }
};

/**
 * Add Multiple Files to Dossier
 * POST /api/v1/medical/dossier-medical/:patientId/multiple-files
 */
export const addFilesToDossier = async (req, res, next) => {
    try {
        const { profileId: userId, role } = req.user;
        const { patientId } = req.params;
        const descriptions = req.body.descriptions ? JSON.parse(req.body.descriptions) : {};

        // Verify access
        if (role === 'patient' && userId.toString() !== patientId.toString()) {
            return sendError(res, 403, 'FORBIDDEN',
                'You can only add files to your own dossier.');
        }

        if (!req.files || req.files.length === 0) {
            return sendError(res, 400, 'NO_FILES',
                'No files provided. Please select files to upload.');
        }

        const uploadedDocuments = [];

        for (const file of req.files) {
            validateFile(file);

            const { s3Key, s3Bucket, s3Url } = await uploadDocumentToS3(
                file.buffer,
                file.originalname,
                file.mimetype,
                patientId,
                'medical_report'
            );

            const document = await MedicalDocument.create({
                patientId,
                uploadedBy: userId,
                uploaderType: role,
                documentType: 'medical_report',
                title: file.originalname,
                description: descriptions[file.originalname] || '',
                fileName: file.originalname,
                fileSize: file.size,
                mimeType: file.mimetype,
                fileExtension: getFileExtension(file.mimetype),
                s3Key,
                s3Bucket,
                s3Url,
                uploadDate: new Date(),
                status: 'active'
            });

            uploadedDocuments.push(document);
        }

        // Re-fetch dossier
        const [documents, consultations, prescriptions] = await Promise.all([
            MedicalDocument.find({
                patientId,
                status: { $in: ['active', 'archived'] }
            }).sort({ uploadDate: -1 }),
            Consultation.find({
                patientId,
                status: { $in: ['completed', 'archived'] }
            }).sort({ consultationDate: -1 }),
            Prescription.find({
                patientId,
                status: { $in: ['active', 'completed'] }
            }).sort({ prescribedDate: -1 })
        ]);

        const formattedDocuments = await formatDocumentList(documents, getSignedUrl);

        const dossier = {
            id: patientId,
            patientId,
            files: formattedDocuments,
            consultations,
            prescriptions
        };

        res.status(201).json({
            data: {
                dossier
            }
        });

    } catch (error) {
        next(error);
    }
};

/**
 * Delete File from Dossier
 * DELETE /api/v1/medical/dossier-medical/:patientId/files/:fileId
 */
export const deleteFile = async (req, res, next) => {
    try {
        const { profileId: userId, role } = req.user;
        const { patientId, fileId } = req.params;

        const document = await MedicalDocument.findById(fileId);

        if (!document) {
            return sendError(res, 404, 'DOCUMENT_NOT_FOUND',
                'The document you are looking for does not exist.');
        }

        // Verify ownership
        if (role === 'patient' && document.patientId.toString() !== userId.toString()) {
            return sendError(res, 403, 'FORBIDDEN',
                'You can only delete files from your own dossier.');
        }

        // Soft delete
        document.status = 'deleted';
        await document.save();

        res.status(200).json({
            message: 'File deleted successfully'
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Update File Description
 * PATCH /api/v1/medical/dossier-medical/:patientId/files/:fileId
 */
export const updateFileDescription = async (req, res, next) => {
    try {
        const { profileId: userId, role } = req.user;
        const { patientId, fileId } = req.params;
        const { description } = req.body;

        const document = await MedicalDocument.findById(fileId);

        if (!document) {
            return sendError(res, 404, 'DOCUMENT_NOT_FOUND',
                'The document you are looking for does not exist.');
        }

        // Verify ownership
        if (role === 'patient' && document.patientId.toString() !== userId.toString()) {
            return sendError(res, 403, 'FORBIDDEN',
                'You can only update files in your own dossier.');
        }

        document.description = description;
        await document.save();

        res.status(200).json({
            message: 'File description updated successfully'
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Doctor: Get Patient Medical History
 * GET /api/v1/medical/patient-history/:patientId
 * 
 * Allows doctors with an appointment relationship to view:
 * - Patient's shared documents
 * - Previous consultations (all doctors, for continuity of care)
 * - Prescriptions (all doctors, to check medications/interactions)
 * 
 * ETHICAL CONSIDERATIONS:
 * - Doctor MUST have confirmed/completed appointment with patient
 * - Documents respect patient's sharing preferences (isSharedWithAllDoctors)
 * - Access is logged for audit/compliance
 * - Sensitive consultations (e.g., psychiatry) can be marked as restricted in future
 */
export const getPatientMedicalHistory = async (req, res, next) => {
    try {
        const { profileId: doctorId, role } = req.user;
        const { patientId } = req.params;

        // Only doctors can access this endpoint
        if (role !== 'doctor') {
            return sendError(res, 403, 'FORBIDDEN',
                'Only doctors can access patient medical history.');
        }

        // Verify doctor has appointment relationship with patient
        const hasRelationship = await checkDoctorPatientRelationship(doctorId, patientId);
        
        if (!hasRelationship) {
            return sendError(res, 403, 'NO_RELATIONSHIP',
                'You must have a completed consultation with this patient to view their medical history.');
        }

        // Fetch patient's medical history
        // 1. Shared documents (respecting patient preferences)
        const sharedDocuments = await MedicalDocument.find({
            patientId,
            status: { $in: ['active', 'archived'] },
            $or: [
                { isSharedWithAllDoctors: true },
                { sharedWithDoctors: doctorId }
            ]
        }).sort({ uploadDate: -1 });

        // 2. All consultations (for continuity of care)
        const allConsultations = await Consultation.find({
            patientId,
            status: { $in: ['completed', 'archived'] }
        }).sort({ consultationDate: -1 }).select({
            appointmentId: 1,
            doctorId: 1,
            consultationDate: 1,
            consultationType: 1,
            chiefComplaint: 1,
            'medicalNote.diagnosis': 1,
            'medicalNote.symptoms': 1,
            'medicalNote.vitalSigns': 1,
            followUpRequired: 1,
            followUpDate: 1
        });

        // 3. All prescriptions (to check current medications and avoid interactions)
        const allPrescriptions = await Prescription.find({
            patientId,
            status: { $in: ['active', 'completed'] }
        }).sort({ prescriptionDate: -1 }).select({
            doctorId: 1,
            prescriptionDate: 1,
            medications: 1,
            status: 1
        });

        // Format documents with signed URLs
        const formattedDocuments = await formatDocumentList(sharedDocuments, getSignedUrl);

        // Log access for audit trail
        console.log(`📋 AUDIT: Doctor ${doctorId} accessed medical history of patient ${patientId} at ${new Date().toISOString()}`);

        // Emit audit event via Kafka (if audit service exists)
        try {
            await kafkaProducer.sendEvent(
                TOPICS.AUDIT?.RECORD_ACCESSED || 'audit.record.accessed',
                createEvent('medical_record.accessed', {
                    doctorId: doctorId.toString(),
                    patientId: patientId.toString(),
                    accessType: 'view_medical_history',
                    accessedAt: new Date().toISOString(),
                    documentsCount: sharedDocuments.length,
                    consultationsCount: allConsultations.length,
                    prescriptionsCount: allPrescriptions.length
                })
            );
        } catch (auditError) {
            console.error('Failed to emit audit event:', auditError.message);
            // Don't fail the request if audit fails
        }

        res.status(200).json({
            patientId,
            accessedBy: doctorId,
            accessedAt: new Date().toISOString(),
            medicalHistory: {
                documents: formattedDocuments,
                consultations: allConsultations,
                prescriptions: allPrescriptions
            },
            summary: {
                totalDocuments: formattedDocuments.length,
                totalConsultations: allConsultations.length,
                totalPrescriptions: allPrescriptions.length,
                // Extract unique diagnoses for quick overview
                diagnoses: [...new Set(
                    allConsultations
                        .filter(c => c.medicalNote?.diagnosis)
                        .map(c => c.medicalNote.diagnosis)
                )],
                // Get current active medications
                currentMedications: allPrescriptions
                    .filter(p => p.status === 'active')
                    .flatMap(p => p.medications.map(m => ({
                        name: m.medicationName,
                        dosage: m.dosage,
                        frequency: m.frequency
                    })))
            }
        });
    } catch (error) {
        next(error);
    }
};
