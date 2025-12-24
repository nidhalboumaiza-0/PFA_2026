import MedicalDocument from '../models/MedicalDocument.js';
import Consultation from '../models/Consultation.js';
import { kafkaProducer, TOPICS, createEvent } from '../../../../shared/index.js';
import {
  uploadDocumentToS3,
  getSignedUrl,
  getDownloadUrl,
  deleteDocumentFromS3
} from '../services/s3DocumentService.js';
import { validateFile, getFileExtension } from '../config/multerDocument.js';
import {
  getUploaderInfo,
  getConsultationInfo,
  hasDoctorTreatedPatient,
  buildDocumentDateQuery,
  buildTagsQuery,
  calculateDocumentPagination,
  formatDocumentForResponse,
  formatDocumentList,
  calculateStorageUsed,
  getDocumentCountsByType
} from '../utils/documentHelpers.js';

/**
 * Upload Medical Document
 * POST /api/v1/medical/documents/upload
 */
export const uploadDocument = async (req, res, next) => {
  try {
    const { id: userId, role } = req.user;
    const {
      patientId: providedPatientId,
      consultationId,
      documentType,
      title,
      description,
      documentDate,
      tags
    } = req.body;

    // Validate file
    if (!req.file) {
      return res.status(400).json({
        message: 'No file provided'
      });
    }

    validateFile(req.file);

    // Determine patient ID and uploader type
    let patientId;
    let uploaderType;
    let uploaderDoctorId = null;

    if (role === 'patient') {
      patientId = userId;
      uploaderType = 'patient';
    } else if (role === 'doctor') {
      if (!providedPatientId) {
        return res.status(400).json({
          message: 'Patient ID is required when doctor uploads document'
        });
      }
      patientId = providedPatientId;
      uploaderType = 'doctor';
      uploaderDoctorId = userId;
    }

    // Verify consultation if provided
    if (consultationId) {
      const consultation = await Consultation.findById(consultationId);
      if (!consultation) {
        return res.status(404).json({
          message: 'Consultation not found'
        });
      }
      if (consultation.patientId.toString() !== patientId.toString()) {
        return res.status(400).json({
          message: 'Consultation does not belong to this patient'
        });
      }
    }

    // Upload file to S3
    const { s3Key, s3Bucket, s3Url } = await uploadDocumentToS3(
      req.file.buffer,
      req.file.originalname,
      req.file.mimetype,
      patientId,
      documentType
    );

    // Create document record
    const document = await MedicalDocument.create({
      patientId,
      uploadedBy: userId,
      uploaderType,
      uploaderDoctorId,
      consultationId: consultationId || undefined,
      documentType,
      title,
      description,
      fileName: req.file.originalname,
      fileSize: req.file.size,
      mimeType: req.file.mimetype,
      fileExtension: getFileExtension(req.file.mimetype),
      s3Key,
      s3Bucket,
      s3Url,
      documentDate: documentDate || undefined,
      tags: tags || [],
      uploadDate: new Date()
    });

    // Link to consultation if provided
    if (consultationId) {
      await Consultation.findByIdAndUpdate(
        consultationId,
        { $push: { documentIds: document._id } }
      );
    }

    // Generate signed URL
    const signedUrl = await getSignedUrl(s3Key, 3600);

    // Publish Kafka event
    await kafkaProducer.sendEvent(
      TOPICS.MEDICAL.DOCUMENT_UPLOADED,
      createEvent('document.uploaded', {
        documentId: document._id.toString(),
        patientId: patientId.toString(),
        uploadedBy: userId.toString(),
        uploaderType,
        documentType,
        consultationId: consultationId || null,
        fileSize: req.file.size
      })
    );

    res.status(201).json({
      message: 'Document uploaded successfully',
      document: {
        id: document._id,
        title: document.title,
        documentType: document.documentType,
        fileName: document.fileName,
        fileSize: document.fileSize,
        formattedFileSize: document.formattedFileSize,
        uploadDate: document.uploadDate,
        signedUrl,
        urlExpiresIn: '1 hour'
      }
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Get Document Details
 * GET /api/v1/medical/documents/:documentId
 */
export const getDocumentById = async (req, res, next) => {
  try {
    const { id: userId, role } = req.user;
    const { documentId } = req.params;

    const document = await MedicalDocument.findById(documentId);

    if (!document) {
      return res.status(404).json({
        message: 'Document not found'
      });
    }

    if (document.status === 'deleted') {
      return res.status(404).json({
        message: 'Document has been deleted'
      });
    }

    // Verify access
    const hasAccess = await document.canUserAccess(userId, role);
    if (!hasAccess) {
      return res.status(403).json({
        message: 'You do not have access to this document'
      });
    }

    // Get uploader info
    const uploaderInfo = await getUploaderInfo(document.uploadedBy, document.uploaderType);

    // Get consultation info if linked
    const consultationInfo = document.consultationId
      ? await getConsultationInfo(Consultation, document.consultationId)
      : null;

    // Generate signed URL
    const signedUrl = await getSignedUrl(document.s3Key, 3600);

    // Publish audit event
    await kafkaProducer.sendEvent(
      TOPICS.MEDICAL.DOCUMENT_ACCESSED,
      createEvent('document.accessed', {
        documentId: document._id.toString(),
        accessedBy: userId.toString(),
        accessType: 'view'
      })
    );

    res.status(200).json({
      document: {
        id: document._id,
        title: document.title,
        description: document.description,
        documentType: document.documentType,
        documentDate: document.documentDate,
        uploadDate: document.uploadDate,
        uploadedBy: uploaderInfo,
        fileInfo: {
          fileName: document.fileName,
          fileSize: document.fileSize,
          formattedFileSize: document.formattedFileSize,
          mimeType: document.mimeType,
          fileExtension: document.fileExtension
        },
        signedUrl,
        urlExpiresIn: '1 hour',
        tags: document.tags,
        linkedConsultation: consultationInfo,
        isSharedWithAllDoctors: document.isSharedWithAllDoctors
      }
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Get Patient's Documents
 * GET /api/v1/medical/documents/patient/:patientId
 */
export const getPatientDocuments = async (req, res, next) => {
  try {
    const { id: doctorId } = req.user;
    const { patientId } = req.params;
    const {
      documentType,
      startDate,
      endDate,
      consultationId,
      tags,
      status,
      page,
      limit
    } = req.query;

    // Verify doctor has treated this patient
    const hasTreated = await hasDoctorTreatedPatient(Consultation, doctorId, patientId);
    if (!hasTreated) {
      return res.status(403).json({
        message: 'You can only view documents for patients you have treated'
      });
    }

    // Build query
    const query = {
      patientId,
      status: status || 'active',
      $or: [
        { isSharedWithAllDoctors: true },
        { sharedWithDoctors: doctorId }
      ]
    };

    if (documentType) query.documentType = documentType;
    if (consultationId) query.consultationId = consultationId;

    // Add date range
    Object.assign(query, buildDocumentDateQuery(startDate, endDate));

    // Add tags filter
    if (tags) {
      Object.assign(query, buildTagsQuery(tags));
    }

    // Get total count
    const totalDocuments = await MedicalDocument.countDocuments(query);

    // Calculate pagination
    const { skip, pagination } = calculateDocumentPagination(page, limit, totalDocuments);

    // Get documents
    const documents = await MedicalDocument.find(query)
      .sort({ uploadDate: -1 })
      .skip(skip)
      .limit(limit);

    // Format documents with signed URLs
    const formattedDocuments = await formatDocumentList(documents, getSignedUrl);

    res.status(200).json({
      documents: formattedDocuments,
      pagination
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Get Documents for Consultation
 * GET /api/v1/medical/consultations/:consultationId/documents
 */
export const getConsultationDocuments = async (req, res, next) => {
  try {
    const { id: userId, role } = req.user;
    const { consultationId } = req.params;

    // Verify consultation exists and user has access
    const consultation = await Consultation.findById(consultationId);
    if (!consultation) {
      return res.status(404).json({
        message: 'Consultation not found'
      });
    }

    // Verify access
    if (role === 'patient' && consultation.patientId.toString() !== userId.toString()) {
      return res.status(403).json({
        message: 'You can only view your own consultation documents'
      });
    }

    if (role === 'doctor') {
      const hasAccess = await consultation.canDoctorAccess(userId);
      if (!hasAccess) {
        return res.status(403).json({
          message: 'You do not have access to this consultation'
        });
      }
    }

    // Get documents
    const documents = await MedicalDocument.find({
      consultationId,
      status: { $in: ['active', 'archived'] }
    }).sort({ uploadDate: -1 });

    // Format documents
    const formattedDocuments = await formatDocumentList(documents, getSignedUrl);

    res.status(200).json({
      documents: formattedDocuments
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Patient: Get My Documents
 * GET /api/v1/medical/documents/my-documents
 */
export const getMyDocuments = async (req, res, next) => {
  try {
    const { id: patientId } = req.user;
    const { documentType, startDate, endDate, status, page, limit } = req.query;

    // Build query
    const query = {
      patientId,
      status: status || 'active'
    };

    if (documentType) query.documentType = documentType;
    Object.assign(query, buildDocumentDateQuery(startDate, endDate));

    // Get total count
    const totalDocuments = await MedicalDocument.countDocuments(query);

    // Calculate pagination
    const { skip, pagination } = calculateDocumentPagination(page, limit, totalDocuments);

    // Get documents
    const documents = await MedicalDocument.find(query)
      .sort({ uploadDate: -1 })
      .skip(skip)
      .limit(limit);

    // Format documents
    const formattedDocuments = await formatDocumentList(documents, getSignedUrl);

    res.status(200).json({
      documents: formattedDocuments,
      pagination
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Update Document Metadata
 * PUT /api/v1/medical/documents/:documentId
 */
export const updateDocument = async (req, res, next) => {
  try {
    const { id: userId } = req.user;
    const { documentId } = req.params;
    const updates = req.body;

    const document = await MedicalDocument.findById(documentId);

    if (!document) {
      return res.status(404).json({
        message: 'Document not found'
      });
    }

    // Verify ownership
    if (!document.canUserEdit(userId)) {
      return res.status(403).json({
        message: 'You can only edit documents you uploaded'
      });
    }

    // Track changes
    const changedFields = Object.keys(updates);

    // Update fields
    if (updates.title) document.title = updates.title;
    if (updates.description !== undefined) document.description = updates.description;
    if (updates.documentDate) document.documentDate = updates.documentDate;
    if (updates.tags) document.tags = updates.tags;
    if (updates.isSharedWithAllDoctors !== undefined) {
      document.isSharedWithAllDoctors = updates.isSharedWithAllDoctors;
    }
    if (updates.sharedWithDoctors) {
      document.sharedWithDoctors = updates.sharedWithDoctors;
    }

    await document.save();

    // Publish Kafka event
    await kafkaProducer.sendEvent(
      TOPICS.MEDICAL.DOCUMENT_UPDATED,
      createEvent('document.updated', {
        documentId: document._id.toString(),
        updatedBy: userId.toString(),
        changes: changedFields
      })
    );

    res.status(200).json({
      message: 'Document updated successfully',
      document: {
        id: document._id,
        title: document.title,
        description: document.description,
        documentDate: document.documentDate,
        tags: document.tags,
        isSharedWithAllDoctors: document.isSharedWithAllDoctors
      }
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Delete Document (Soft Delete)
 * DELETE /api/v1/medical/documents/:documentId
 */
export const deleteDocument = async (req, res, next) => {
  try {
    const { id: userId } = req.user;
    const { documentId } = req.params;

    const document = await MedicalDocument.findById(documentId);

    if (!document) {
      return res.status(404).json({
        message: 'Document not found'
      });
    }

    // Verify ownership
    if (!document.canUserDelete(userId)) {
      return res.status(403).json({
        message: 'You can only delete documents you uploaded'
      });
    }

    // Soft delete
    document.status = 'deleted';
    await document.save();

    // Optionally delete from S3 (commented out for audit purposes)
    // await deleteDocumentFromS3(document.s3Key);

    // Publish Kafka event
    await kafkaProducer.sendEvent(
      TOPICS.MEDICAL.DOCUMENT_DELETED,
      createEvent('document.deleted', {
        documentId: document._id.toString(),
        deletedBy: userId.toString()
      })
    );

    res.status(200).json({
      message: 'Document deleted successfully'
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Download Document
 * GET /api/v1/medical/documents/:documentId/download
 */
export const downloadDocument = async (req, res, next) => {
  try {
    const { id: userId, role } = req.user;
    const { documentId } = req.params;

    const document = await MedicalDocument.findById(documentId);

    if (!document) {
      return res.status(404).json({
        message: 'Document not found'
      });
    }

    if (document.status === 'deleted') {
      return res.status(404).json({
        message: 'Document has been deleted'
      });
    }

    // Verify access
    const hasAccess = await document.canUserAccess(userId, role);
    if (!hasAccess) {
      return res.status(403).json({
        message: 'You do not have access to this document'
      });
    }

    // Generate download URL (expires in 5 minutes)
    const downloadUrl = await getDownloadUrl(document.s3Key, document.fileName, 300);

    // Publish audit event
    await kafkaProducer.sendEvent(
      TOPICS.MEDICAL.DOCUMENT_ACCESSED,
      createEvent('document.accessed', {
        documentId: document._id.toString(),
        accessedBy: userId.toString(),
        accessType: 'download'
      })
    );

    res.status(200).json({
      downloadUrl,
      fileName: document.fileName,
      expiresIn: '5 minutes'
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Update Document Sharing
 * PUT /api/v1/medical/documents/:documentId/sharing
 */
export const updateDocumentSharing = async (req, res, next) => {
  try {
    const { id: patientId } = req.user;
    const { documentId } = req.params;
    const { isSharedWithAllDoctors, sharedWithDoctors } = req.body;

    const document = await MedicalDocument.findById(documentId);

    if (!document) {
      return res.status(404).json({
        message: 'Document not found'
      });
    }

    // Verify patient owns this document
    if (document.patientId.toString() !== patientId.toString()) {
      return res.status(403).json({
        message: 'You can only manage sharing for your own documents'
      });
    }

    document.isSharedWithAllDoctors = isSharedWithAllDoctors;
    if (sharedWithDoctors) {
      document.sharedWithDoctors = sharedWithDoctors;
    } else if (!isSharedWithAllDoctors) {
      document.sharedWithDoctors = [];
    }

    await document.save();

    // Publish Kafka event
    await kafkaProducer.sendEvent(
      TOPICS.MEDICAL.DOCUMENT_SHARED,
      createEvent('document.sharing_updated', {
        documentId: document._id.toString(),
        patientId: patientId.toString(),
        isSharedWithAllDoctors,
        sharedDoctorCount: document.sharedWithDoctors.length
      })
    );

    res.status(200).json({
      message: 'Document sharing updated successfully',
      sharing: {
        isSharedWithAllDoctors: document.isSharedWithAllDoctors,
        sharedWithDoctors: document.sharedWithDoctors
      }
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Get Document Statistics
 * GET /api/v1/medical/documents/statistics
 */
export const getDocumentStatistics = async (req, res, next) => {
  try {
    const { id: userId, role } = req.user;

    if (role === 'patient') {
      // Patient statistics
      const totalDocuments = await MedicalDocument.countDocuments({
        patientId: userId,
        status: { $in: ['active', 'archived'] }
      });

      const byType = await getDocumentCountsByType(userId);
      const storage = await calculateStorageUsed(userId);

      res.status(200).json({
        statistics: {
          totalDocuments,
          byType,
          totalStorageUsed: storage.formatted
        }
      });
    } else if (role === 'doctor') {
      // Doctor statistics
      const documentsUploaded = await MedicalDocument.countDocuments({
        uploadedBy: userId,
        uploaderType: 'doctor',
        status: { $in: ['active', 'archived'] }
      });

      const patientsWithDocuments = await MedicalDocument.distinct('patientId', {
        uploadedBy: userId,
        uploaderType: 'doctor',
        status: { $in: ['active', 'archived'] }
      });

      const startOfMonth = new Date();
      startOfMonth.setDate(1);
      startOfMonth.setHours(0, 0, 0, 0);

      const thisMonth = await MedicalDocument.countDocuments({
        uploadedBy: userId,
        uploaderType: 'doctor',
        uploadDate: { $gte: startOfMonth }
      });

      res.status(200).json({
        statistics: {
          documentsUploaded,
          patientsWithDocuments: patientsWithDocuments.length,
          thisMonth
        }
      });
    }
  } catch (error) {
    next(error);
  }
};
