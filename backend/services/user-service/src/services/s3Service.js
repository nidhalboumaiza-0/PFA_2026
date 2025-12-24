import AWS from 'aws-sdk';
import fs from 'fs';
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
    secretAccessKey: getConfig('AWS_SECRET_ACCESS_KEY')
  });
  s3 = new AWS.S3();
  console.log('✅ S3 client initialized with config from Consul');
};

/**
 * Get S3 bucket name from Consul config
 */
const getBucket = () => getConfig('AWS_S3_BUCKET');

/**
 * Upload file to S3
 * @param {Object} file - File object from multer
 * @param {String} folder - Folder path in S3 bucket (e.g., 'profiles/')
 * @returns {Promise<String>} S3 file URL
 */
export const uploadToS3 = async (file, folder = '') => {
  try {
    const fileContent = fs.readFileSync(file.path);
    
    const params = {
      Bucket: getBucket(),
      Key: `${folder}${file.filename}`,
      Body: fileContent,
      ContentType: file.mimetype,
      ACL: 'private' // Use private ACL and signed URLs for access
    };

    const result = await s3.upload(params).promise();
    
    // Delete temp file
    fs.unlinkSync(file.path);
    
    return result.Location;
  } catch (error) {
    // Delete temp file if upload fails
    if (fs.existsSync(file.path)) {
      fs.unlinkSync(file.path);
    }
    throw error;
  }
};

/**
 * Get signed URL for private S3 object
 * @param {String} fileKey - S3 object key
 * @param {Number} expiresIn - URL expiration in seconds (default: 3600 = 1 hour)
 * @returns {Promise<String>} Signed URL
 */
export const getSignedUrl = async (fileKey, expiresIn = 3600) => {
  try {
    const params = {
      Bucket: getBucket(),
      Key: fileKey,
      Expires: expiresIn
    };

    const url = await s3.getSignedUrlPromise('getObject', params);
    return url;
  } catch (error) {
    throw error;
  }
};

/**
 * Delete file from S3
 * @param {String} fileUrl - S3 file URL or key
 * @returns {Promise<void>}
 */
export const deleteFromS3 = async (fileUrl) => {
  try {
    // Extract key from URL if full URL is provided
    let fileKey = fileUrl;
    
    if (fileUrl.includes('amazonaws.com')) {
      const urlParts = fileUrl.split('.amazonaws.com/');
      fileKey = urlParts[1] || fileUrl;
    }

    const params = {
      Bucket: getBucket(),
      Key: fileKey
    };

    await s3.deleteObject(params).promise();
    console.log(`✅ Deleted file from S3: ${fileKey}`);
  } catch (error) {
    console.error('❌ Error deleting file from S3:', error);
    // Don't throw error - deletion failure shouldn't break the flow
  }
};

/**
 * Check if file exists in S3
 * @param {String} fileKey - S3 object key
 * @returns {Promise<Boolean>}
 */
export const fileExistsInS3 = async (fileKey) => {
  try {
    const params = {
      Bucket: getBucket(),
      Key: fileKey
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

export default {
  uploadToS3,
  getSignedUrl,
  deleteFromS3,
  fileExistsInS3
};
