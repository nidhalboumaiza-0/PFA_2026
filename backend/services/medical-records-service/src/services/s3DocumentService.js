import AWS from 'aws-sdk';
import { v4 as uuidv4 } from 'uuid';
import path from 'path';
import { getConfig } from '../../../../shared/index.js';

// S3 client - initialized after bootstrap
let s3 = null;

const DOCUMENTS_FOLDER = 'medical-documents';

/**
 * Initialize S3 client with config from Consul
 */
export const initializeS3 = () => {
  s3 = new AWS.S3({
    accessKeyId: getConfig('AWS_ACCESS_KEY_ID'),
    secretAccessKey: getConfig('AWS_SECRET_ACCESS_KEY'),
    region: getConfig('AWS_REGION', 'eu-north-1'),
    signatureVersion: 'v4'  // Required for signed URLs
  });
  console.log('✅ Medical-records S3 client initialized with config from Consul (Signature v4)');
};

/**
 * Get S3 bucket name from Consul config
 */
const getBucket = () => getConfig('AWS_S3_BUCKET', 'esante-medical-documents');

/**
 * Upload document to S3
 * @param {Buffer} fileBuffer - File buffer
 * @param {String} fileName - Original filename
 * @param {String} mimeType - File MIME type
 * @param {String} patientId - Patient ID
 * @param {String} documentType - Type of document
 * @returns {Object} - S3 upload result with key and bucket
 */
export const uploadDocumentToS3 = async (fileBuffer, fileName, mimeType, patientId, documentType) => {
  try {
    const fileExtension = path.extname(fileName).toLowerCase().replace('.', '');
    const timestamp = Date.now();
    const uniqueId = uuidv4().substring(0, 8);

    // Create S3 key with folder structure
    const s3Key = `${DOCUMENTS_FOLDER}/${documentType}/patient_${patientId}_${timestamp}_${uniqueId}.${fileExtension}`;

    const params = {
      Bucket: getBucket(),
      Key: s3Key,
      Body: fileBuffer,
      ContentType: mimeType,
      ServerSideEncryption: 'AES256', // Enable encryption at rest
      Metadata: {
        patientId: patientId.toString(),
        documentType: documentType,
        uploadTimestamp: timestamp.toString()
      }
    };

    const result = await s3.upload(params).promise();

    return {
      s3Key,
      s3Bucket: getBucket(),
      s3Url: result.Location,
      etag: result.ETag
    };
  } catch (error) {
    console.error('S3 Upload Error:', error);
    throw new Error('Failed to upload document to S3: ' + error.message);
  }
};

/**
 * Generate signed URL for secure document access
 * @param {String} s3Key - S3 object key
 * @param {Number} expiresIn - URL expiration time in seconds (default: 1 hour)
 * @returns {String} - Signed URL
 */
export const getSignedUrl = async (s3Key, expiresIn = 3600) => {
  try {
    const params = {
      Bucket: getBucket(),
      Key: s3Key,
      Expires: expiresIn
    };

    const signedUrl = await s3.getSignedUrlPromise('getObject', params);
    return signedUrl;
  } catch (error) {
    console.error('Get Signed URL Error:', error);
    throw new Error('Failed to generate signed URL: ' + error.message);
  }
};

/**
 * Generate signed URL for document download
 * @param {String} s3Key - S3 object key
 * @param {String} fileName - Original filename for download
 * @param {Number} expiresIn - URL expiration time in seconds (default: 5 minutes)
 * @returns {String} - Signed download URL
 */
export const getDownloadUrl = async (s3Key, fileName, expiresIn = 300) => {
  try {
    const params = {
      Bucket: getBucket(),
      Key: s3Key,
      Expires: expiresIn,
      ResponseContentDisposition: `attachment; filename="${fileName}"`
    };

    const signedUrl = await s3.getSignedUrlPromise('getObject', params);
    return signedUrl;
  } catch (error) {
    console.error('Get Download URL Error:', error);
    throw new Error('Failed to generate download URL: ' + error.message);
  }
};

/**
 * Delete document from S3
 * @param {String} s3Key - S3 object key
 * @returns {Object} - Delete result
 */
export const deleteDocumentFromS3 = async (s3Key) => {
  try {
    const params = {
      Bucket: getBucket(),
      Key: s3Key
    };

    const result = await s3.deleteObject(params).promise();
    return result;
  } catch (error) {
    console.error('S3 Delete Error:', error);
    throw new Error('Failed to delete document from S3: ' + error.message);
  }
};

/**
 * Check if file exists in S3
 * @param {String} s3Key - S3 object key
 * @returns {Boolean} - True if exists
 */
export const fileExistsInS3 = async (s3Key) => {
  try {
    const params = {
      Bucket: getBucket(),
      Key: s3Key
    };

    await s3.headObject(params).promise();
    return true;
  } catch (error) {
    if (error.code === 'NotFound') {
      return false;
    }
    throw error;
  }
};

/**
 * Get file metadata from S3
 * @param {String} s3Key - S3 object key
 * @returns {Object} - File metadata
 */
export const getFileMetadata = async (s3Key) => {
  try {
    const params = {
      Bucket: getBucket(),
      Key: s3Key
    };

    const metadata = await s3.headObject(params).promise();
    return {
      contentType: metadata.ContentType,
      contentLength: metadata.ContentLength,
      lastModified: metadata.LastModified,
      metadata: metadata.Metadata
    };
  } catch (error) {
    console.error('Get File Metadata Error:', error);
    throw new Error('Failed to get file metadata: ' + error.message);
  }
};

/**
 * Copy document to a new location in S3
 * @param {String} sourceKey - Source S3 key
 * @param {String} destKey - Destination S3 key
 * @returns {Object} - Copy result
 */
export const copyDocument = async (sourceKey, destKey) => {
  try {
    const params = {
      Bucket: getBucket(),
      CopySource: `${getBucket()}/${sourceKey}`,
      Key: destKey
    };

    const result = await s3.copyObject(params).promise();
    return result;
  } catch (error) {
    console.error('S3 Copy Error:', error);
    throw new Error('Failed to copy document: ' + error.message);
  }
};

/**
 * List documents for a patient
 * @param {String} patientId - Patient ID
 * @param {Number} maxKeys - Maximum number of keys to return
 * @returns {Array} - List of S3 objects
 */
export const listPatientDocuments = async (patientId, maxKeys = 1000) => {
  try {
    const params = {
      Bucket: getBucket(),
      Prefix: `${DOCUMENTS_FOLDER}/`,
      MaxKeys: maxKeys
    };

    const result = await s3.listObjectsV2(params).promise();

    // Filter by patient ID in key
    const patientDocs = result.Contents.filter(obj =>
      obj.Key.includes(`patient_${patientId}_`)
    );

    return patientDocs;
  } catch (error) {
    console.error('List Documents Error:', error);
    throw new Error('Failed to list documents: ' + error.message);
  }
};

export default {
  uploadDocumentToS3,
  getSignedUrl,
  getDownloadUrl,
  deleteDocumentFromS3,
  fileExistsInS3,
  getFileMetadata,
  copyDocument,
  listPatientDocuments
};
