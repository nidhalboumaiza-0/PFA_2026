import axios from 'axios';
import MedicalDocument from '../models/MedicalDocument.js';
import { getUserServiceUrl } from '../../../../shared/index.js';

/**
 * Fetch uploader information (patient or doctor)
 */
export const getUploaderInfo = async (uploaderId, uploaderType) => {
  try {
    const userServiceUrl = await getUserServiceUrl();
    const endpoint = uploaderType === 'patient' 
      ? `${userServiceUrl}/api/v1/users/patients/${uploaderId}`
      : `${userServiceUrl}/api/v1/users/doctors/${uploaderId}`;
    
    const response = await axios.get(endpoint);
    const userData = uploaderType === 'patient' ? response.data.patient : response.data.doctor;
    
    return {
      id: userData._id,
      name: userData.fullName || `${userData.firstName} ${userData.lastName}`,
      type: uploaderType
    };
  } catch (error) {
    return {
      id: uploaderId,
      name: 'Unknown User',
      type: uploaderType
    };
  }
};

/**
 * Get consultation info
 */
export const getConsultationInfo = async (Consultation, consultationId) => {
  try {
    const consultation = await Consultation.findById(consultationId)
      .select('consultationDate doctorId');
    
    if (!consultation) return null;
    
    const doctorInfo = await getUploaderInfo(consultation.doctorId, 'doctor');
    
    return {
      id: consultation._id,
      date: consultation.consultationDate,
      doctor: doctorInfo.name
    };
  } catch (error) {
    return null;
  }
};

/**
 * Check if doctor has treated patient
 */
export const hasDoctorTreatedPatient = async (Consultation, doctorId, patientId) => {
  const consultation = await Consultation.findOne({
    doctorId,
    patientId
  });
  return !!consultation;
};

/**
 * Build date range query for documents
 */
export const buildDocumentDateQuery = (startDate, endDate) => {
  const query = {};
  
  if (startDate || endDate) {
    query.uploadDate = {};
    if (startDate) {
      query.uploadDate.$gte = new Date(startDate);
    }
    if (endDate) {
      const end = new Date(endDate);
      end.setHours(23, 59, 59, 999);
      query.uploadDate.$lte = end;
    }
  }
  
  return query;
};

/**
 * Build tags query
 */
export const buildTagsQuery = (tags) => {
  if (!tags) return {};
  
  const tagArray = Array.isArray(tags) ? tags : tags.split(',').map(t => t.trim());
  
  return {
    tags: { $in: tagArray.map(t => t.toLowerCase()) }
  };
};

/**
 * Calculate pagination
 */
export const calculateDocumentPagination = (page, limit, totalCount) => {
  const totalPages = Math.ceil(totalCount / limit);
  const skip = (page - 1) * limit;
  
  return {
    skip,
    pagination: {
      currentPage: page,
      totalPages,
      totalDocuments: totalCount
    }
  };
};

/**
 * Format document for response (with signed URL)
 */
export const formatDocumentForResponse = async (document, getSignedUrl, includeFullDetails = false) => {
  const signedUrl = await getSignedUrl(document.s3Key, 3600);
  
  const formatted = {
    id: document._id,
    title: document.title,
    documentType: document.documentType,
    documentDate: document.documentDate,
    uploadDate: document.uploadDate,
    fileSize: document.fileSize,
    formattedFileSize: document.formattedFileSize,
    mimeType: document.mimeType,
    signedUrl,
    urlExpiresIn: '1 hour'
  };
  
  if (includeFullDetails) {
    formatted.description = document.description;
    formatted.fileName = document.fileName;
    formatted.fileExtension = document.fileExtension;
    formatted.tags = document.tags;
    formatted.status = document.status;
    formatted.isSharedWithAllDoctors = document.isSharedWithAllDoctors;
  }
  
  return formatted;
};

/**
 * Format document list for timeline/history view
 */
export const formatDocumentList = async (documents, getSignedUrl) => {
  return Promise.all(
    documents.map(async (doc) => {
      const signedUrl = await getSignedUrl(doc.s3Key, 3600);
      const uploaderInfo = await getUploaderInfo(doc.uploadedBy, doc.uploaderType);
      
      return {
        id: doc._id,
        title: doc.title,
        documentType: doc.documentType,
        documentDate: doc.documentDate,
        uploadDate: doc.uploadDate,
        uploadedBy: uploaderInfo.name,
        fileSize: doc.fileSize,
        formattedFileSize: doc.formattedFileSize,
        mimeType: doc.mimeType,
        signedUrl
      };
    })
  );
};

/**
 * Calculate storage used by patient
 */
export const calculateStorageUsed = async (patientId) => {
  const documents = await MedicalDocument.find({
    patientId,
    status: { $in: ['active', 'archived'] }
  }).select('fileSize');
  
  const totalBytes = documents.reduce((sum, doc) => sum + doc.fileSize, 0);
  
  // Format bytes to human-readable
  const formatBytes = (bytes) => {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return Math.round((bytes / Math.pow(k, i)) * 100) / 100 + ' ' + sizes[i];
  };
  
  return {
    totalBytes,
    formatted: formatBytes(totalBytes)
  };
};

/**
 * Get documents count by type
 */
export const getDocumentCountsByType = async (patientId) => {
  const counts = await MedicalDocument.aggregate([
    {
      $match: {
        patientId: patientId,
        status: { $in: ['active', 'archived'] }
      }
    },
    {
      $group: {
        _id: '$documentType',
        count: { $sum: 1 }
      }
    }
  ]);
  
  const countsByType = {};
  counts.forEach(item => {
    countsByType[item._id] = item.count;
  });
  
  return countsByType;
};

/**
 * Create audit log for document action
 */
export const createDocumentAuditLog = (action, performedBy, documentId, metadata = {}) => {
  return {
    action,
    performedBy: performedBy.toString(),
    resourceType: 'medical_document',
    resourceId: documentId.toString(),
    timestamp: new Date(),
    ...metadata
  };
};
