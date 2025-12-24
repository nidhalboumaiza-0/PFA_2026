import { mongoose } from '../../../../shared/index.js';

const medicalDocumentSchema = new mongoose.Schema({
  patientId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Patient',
    required: true,
    index: true
  },
  uploadedBy: {
    type: mongoose.Schema.Types.ObjectId,
    required: true
  },
  uploaderType: {
    type: String,
    enum: ['patient', 'doctor'],
    required: true
  },
  uploaderDoctorId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Doctor'
  },
  consultationId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Consultation',
    index: true
  },
  documentType: {
    type: String,
    enum: ['lab_result', 'imaging', 'prescription', 'insurance', 'medical_report', 'other'],
    required: true,
    index: true
  },
  title: {
    type: String,
    required: true,
    trim: true,
    maxlength: 200
  },
  description: {
    type: String,
    trim: true,
    maxlength: 1000
  },
  fileName: {
    type: String,
    required: true
  },
  fileSize: {
    type: Number,
    required: true
  },
  mimeType: {
    type: String,
    required: true,
    enum: ['application/pdf', 'image/jpeg', 'image/jpg', 'image/png']
  },
  fileExtension: {
    type: String,
    required: true,
    enum: ['pdf', 'jpg', 'jpeg', 'png']
  },
  s3Key: {
    type: String,
    required: true,
    unique: true,
    index: true
  },
  s3Bucket: {
    type: String,
    required: true
  },
  s3Url: {
    type: String
  },
  documentDate: {
    type: Date
  },
  uploadDate: {
    type: Date,
    required: true,
    default: Date.now,
    index: true
  },
  isSharedWithAllDoctors: {
    type: Boolean,
    default: true
  },
  sharedWithDoctors: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Doctor'
  }],
  tags: [{
    type: String,
    trim: true,
    lowercase: true
  }],
  status: {
    type: String,
    enum: ['active', 'archived', 'deleted'],
    default: 'active',
    index: true
  }
}, {
  timestamps: true
});

// Compound Indexes
medicalDocumentSchema.index({ patientId: 1, uploadDate: -1 });
medicalDocumentSchema.index({ uploadedBy: 1, uploadDate: -1 });
medicalDocumentSchema.index({ patientId: 1, documentType: 1, uploadDate: -1 });
medicalDocumentSchema.index({ patientId: 1, status: 1, uploadDate: -1 });

// Virtual for formatted file size
medicalDocumentSchema.virtual('formattedFileSize').get(function () {
  const bytes = this.fileSize;
  if (bytes === 0) return '0 Bytes';

  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));

  return Math.round((bytes / Math.pow(k, i)) * 100) / 100 + ' ' + sizes[i];
});

// Method to check if user can access document
medicalDocumentSchema.methods.canUserAccess = async function (userId, userRole) {
  // If patient, must be their document
  if (userRole === 'patient') {
    return this.patientId.toString() === userId.toString();
  }

  // If doctor
  if (userRole === 'doctor') {
    // If shared with all doctors, check if doctor has treated patient
    if (this.isSharedWithAllDoctors) {
      const Consultation = mongoose.model('Consultation');
      const hasTreated = await Consultation.findOne({
        patientId: this.patientId,
        doctorId: userId
      });
      return !!hasTreated;
    }

    // Check if in shared list
    return this.sharedWithDoctors.some(docId => docId.toString() === userId.toString());
  }

  return false;
};

// Method to check if user can edit document
medicalDocumentSchema.methods.canUserEdit = function (userId) {
  return this.uploadedBy.toString() === userId.toString() && this.status === 'active';
};

// Method to check if user can delete document
medicalDocumentSchema.methods.canUserDelete = function (userId) {
  return this.uploadedBy.toString() === userId.toString() && this.status === 'active';
};

const MedicalDocument = mongoose.model('MedicalDocument', medicalDocumentSchema);

export default MedicalDocument;
