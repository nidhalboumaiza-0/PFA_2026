import multer from 'multer';
import path from 'path';

// Allowed MIME types
const ALLOWED_MIME_TYPES = [
  'application/pdf',
  'image/jpeg',
  'image/jpg',
  'image/png'
];

// Maximum file size: 10MB
const MAX_FILE_SIZE = 10 * 1024 * 1024;

// Configure multer storage (memory storage for S3 upload)
const storage = multer.memoryStorage();

// File filter
const fileFilter = (req, file, cb) => {
  // Check MIME type
  if (!ALLOWED_MIME_TYPES.includes(file.mimetype)) {
    return cb(
      new Error('Invalid file type. Only PDF, JPEG, JPG, and PNG files are allowed.'),
      false
    );
  }
  
  cb(null, true);
};

// Configure multer upload
const upload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: MAX_FILE_SIZE,
    files: 1 // Only allow 1 file per upload
  }
});

// Error handler middleware for multer errors
export const handleMulterError = (err, req, res, next) => {
  if (err instanceof multer.MulterError) {
    if (err.code === 'LIMIT_FILE_SIZE') {
      return res.status(400).json({
        message: 'File too large. Maximum size is 10MB.'
      });
    }
    if (err.code === 'LIMIT_FILE_COUNT') {
      return res.status(400).json({
        message: 'Too many files. Only 1 file allowed per upload.'
      });
    }
    if (err.code === 'LIMIT_UNEXPECTED_FILE') {
      return res.status(400).json({
        message: 'Unexpected field name. Use "file" as the field name.'
      });
    }
    return res.status(400).json({
      message: 'File upload error: ' + err.message
    });
  }
  
  if (err) {
    return res.status(400).json({
      message: err.message
    });
  }
  
  next();
};

// Validate file manually (additional check)
export const validateFile = (file) => {
  if (!file) {
    throw new Error('No file provided');
  }
  
  if (!ALLOWED_MIME_TYPES.includes(file.mimetype)) {
    throw new Error('Invalid file type. Only PDF and images (JPEG, PNG) are allowed.');
  }
  
  if (file.size > MAX_FILE_SIZE) {
    throw new Error('File too large. Maximum size is 10MB.');
  }
  
  return true;
};

// Get file extension from MIME type
export const getFileExtension = (mimetype) => {
  const extensions = {
    'application/pdf': 'pdf',
    'image/jpeg': 'jpg',
    'image/jpg': 'jpg',
    'image/png': 'png'
  };
  
  return extensions[mimetype] || 'unknown';
};

// Export configured upload middleware
export const uploadMiddleware = upload;

export default upload;
