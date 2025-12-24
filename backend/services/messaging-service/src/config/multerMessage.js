import multer from 'multer';

const MAX_FILE_SIZE = parseInt(process.env.MAX_FILE_SIZE) || 10485760; // 10MB default

// Use memory storage for direct S3 upload
const storage = multer.memoryStorage();

// File filter
const fileFilter = (req, file, cb) => {
  // Allowed MIME types
  const allowedImageTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif'];
  const allowedDocTypes = [
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  ];
  const allowedTypes = [...allowedImageTypes, ...allowedDocTypes];

  if (allowedTypes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(
      new Error(
        'Invalid file type. Only images (JPEG, PNG, GIF) and documents (PDF, Word, Excel) are allowed.'
      ),
      false
    );
  }
};

// Multer configuration for message attachments
export const uploadMessageFile = multer({
  storage,
  limits: {
    fileSize: MAX_FILE_SIZE,
  },
  fileFilter,
});
