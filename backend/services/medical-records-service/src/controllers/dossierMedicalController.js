import MedicalDocument from '../models/MedicalDocument.js';
import Consultation from '../models/Consultation.js';
import Prescription from '../models/Prescription.js';
import { kafkaProducer, TOPICS, createEvent, sendError, sendSuccess } from '../../../../shared/index.js';
import {
    uploadDocumentToS3,
    getSignedUrl,
    deleteDocumentFromS3
} from '../services/s3DocumentService.js';
import { validateFile, getFileExtension } from '../config/multerDocument.js';
import { formatDocumentList } from '../utils/documentHelpers.js';

/**
 * Get Dossier Medical
 * GET /api/v1/medical/dossier-medical/:patientId
 */
export const getDossierMedical = async (req, res, next) => {
    try {
        const { id: userId, role } = req.user;
        const { patientId } = req.params;

        // Verify access
        if (role === 'patient' && userId.toString() !== patientId.toString()) {
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
        const { id: userId, role } = req.user;
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
        const { id: userId, role } = req.user;
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
        const { id: userId, role } = req.user;
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
        const { id: userId, role } = req.user;
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
