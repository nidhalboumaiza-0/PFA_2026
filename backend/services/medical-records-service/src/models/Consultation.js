import { mongoose } from '../../../../shared/index.js';

const vitalSignsSchema = new mongoose.Schema({
  temperature: {
    type: Number,
    min: 30,
    max: 45
  },
  bloodPressure: {
    type: String,
    match: /^\d{2,3}\/\d{2,3}$/
  },
  heartRate: {
    type: Number,
    min: 40,
    max: 200
  },
  respiratoryRate: {
    type: Number,
    min: 8,
    max: 40
  },
  oxygenSaturation: {
    type: Number,
    min: 0,
    max: 100
  },
  weight: {
    type: Number,
    min: 0,
    max: 500
  },
  height: {
    type: Number,
    min: 0,
    max: 300
  }
}, { _id: false });

const medicalNoteSchema = new mongoose.Schema({
  symptoms: [{
    type: String,
    trim: true
  }],
  diagnosis: {
    type: String,
    trim: true
  },
  physicalExamination: {
    type: String,
    trim: true
  },
  vitalSigns: vitalSignsSchema,
  labResults: {
    type: String,
    trim: true
  },
  additionalNotes: {
    type: String,
    trim: true
  }
}, { _id: false });

const consultationSchema = new mongoose.Schema({
  appointmentId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Appointment',
    required: true,
    unique: true,
    index: true
  },
  patientId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Patient',
    required: true,
    index: true
  },
  doctorId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Doctor',
    required: true,
    index: true
  },
  consultationDate: {
    type: Date,
    required: true,
    index: true
  },
  consultationType: {
    type: String,
    enum: ['in-person', 'follow-up', 'referral'],
    default: 'in-person'
  },
  chiefComplaint: {
    type: String,
    required: true,
    trim: true,
    maxlength: 1000
  },
  medicalNote: {
    type: medicalNoteSchema,
    required: true
  },
  prescriptionId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Prescription'
  },
  documentIds: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'MedicalDocument'
  }],
  requiresFollowUp: {
    type: Boolean,
    default: false
  },
  followUpDate: {
    type: Date
  },
  followUpNotes: {
    type: String,
    trim: true,
    maxlength: 500
  },
  isFromReferral: {
    type: Boolean,
    default: false
  },
  referralId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Referral'
  },
  status: {
    type: String,
    enum: ['draft', 'completed', 'archived'],
    default: 'completed',
    index: true
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Doctor',
    required: true
  },
  lastModifiedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Doctor'
  }
}, {
  timestamps: true
});

// Compound Indexes for efficient queries
consultationSchema.index({ patientId: 1, consultationDate: -1 });
consultationSchema.index({ doctorId: 1, consultationDate: -1 });
consultationSchema.index({ patientId: 1, status: 1, consultationDate: -1 });

// Text index for search functionality
consultationSchema.index({
  chiefComplaint: 'text',
  'medicalNote.diagnosis': 'text',
  'medicalNote.symptoms': 'text'
});

// Virtual for formatted consultation date
consultationSchema.virtual('formattedDate').get(function () {
  return this.consultationDate.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  });
});

// Method to check if doctor has access to this consultation
consultationSchema.methods.canDoctorAccess = async function (doctorId) {
  // Doctor who created it can access
  if (this.doctorId.toString() === doctorId.toString()) {
    return true;
  }

  // Check if doctor has treated this patient before
  const Consultation = this.constructor;
  const hasAccess = await Consultation.findOne({
    patientId: this.patientId,
    doctorId: doctorId
  });

  return !!hasAccess;
};

// Method to check if consultation can be modified
consultationSchema.methods.canBeModified = function () {
  // Check if consultation is older than 24 hours
  const hoursSinceCreation = (Date.now() - this.createdAt.getTime()) / (1000 * 60 * 60);
  return hoursSinceCreation < 24 && this.status !== 'archived';
};

const Consultation = mongoose.model('Consultation', consultationSchema);

export default Consultation;
