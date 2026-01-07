import AWS from 'aws-sdk';
import { v4 as uuidv4 } from 'uuid';
import { getConfig } from '../../../../shared/index.js';

// Configure AWS - will be initialized after bootstrap
let s3 = null;

/**
 * Initialize S3 client with config from Consul
 * Called after bootstrap() in server.js
 */
export const initializeS3 = () => {
  AWS.config.update({
    region: getConfig('AWS_REGION'),
    accessKeyId: getConfig('AWS_ACCESS_KEY_ID'),
    secretAccessKey: getConfig('AWS_SECRET_ACCESS_KEY'),
    signatureVersion: 'v4'
  });
  s3 = new AWS.S3({
    signatureVersion: 'v4'
  });
  console.log('✅ S3 client initialized for RDV service');
};

/**
 * Get S3 bucket name from Consul config
 */
const getBucket = () => getConfig('AWS_S3_BUCKET');

/**
 * Upload file to S3 for appointment documents
 * @param {Object} file - File object from multer (with buffer for memoryStorage)
 * @param {String} appointmentId - Appointment ID for folder structure
 * @returns {Promise<Object>} File metadata including S3 URL
 */
export const uploadDocumentToS3 = async (file, appointmentId) => {
  try {
    const fileExtension = file.originalname.split('.').pop();
    const fileName = `${Date.now()}_${uuidv4()}.${fileExtension}`;
    const s3Key = `appointments/${appointmentId}/documents/${fileName}`;

    const params = {
      Bucket: getBucket(),
      Key: s3Key,
      Body: file.buffer,
      ContentType: file.mimetype,
      ACL: 'private',
    };

    const uploadResult = await s3.upload(params).promise();

    return {
      fileName: file.originalname,
      fileSize: file.size,
      mimeType: file.mimetype,
      s3Key,
      s3Url: uploadResult.Location,
    };
  } catch (error) {
    console.error('Error uploading document to S3:', error.message);
    throw new Error('Failed to upload document');
  }
};

/**
 * Delete file from S3
 */
export const deleteDocumentFromS3 = async (s3Key) => {
  try {
    const params = {
      Bucket: getBucket(),
      Key: s3Key,
    };

    await s3.deleteObject(params).promise();
    return true;
  } catch (error) {
    console.error('Error deleting document from S3:', error.message);
    return false;
  }
};

/**
 * Generate signed URL for S3 document (for secure download)
 * Matches the pattern from user-service for consistency
 * @param {String} s3Key - S3 object key or full URL
 * @param {Number} expiresIn - URL expiration in seconds (default: 3600 = 1 hour)
 * @returns {Promise<String|null>} Signed URL or null if error
 */
export const getSignedDocumentUrl = async (s3Key, expiresIn = 3600) => {
  if (!s3Key) return null;

  try {
    // Extract S3 key from full URL if needed
    let fileKey = s3Key;
    if (s3Key.includes('amazonaws.com')) {
      const urlParts = s3Key.split('.amazonaws.com/');
      fileKey = urlParts[1] || s3Key;
    }

    const params = {
      Bucket: getBucket(),
      Key: fileKey,
      Expires: expiresIn,
    };

    const url = await s3.getSignedUrlPromise('getObject', params);
    return url;
  } catch (error) {
    console.error('Error generating signed URL:', error.message);
    return null;
  }
};
