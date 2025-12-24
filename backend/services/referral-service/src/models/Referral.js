import { mongoose } from '../../../../shared/index.js';

const statusHistorySchema = new mongoose.Schema({
  status: {
    type: String,
    required: true
  },
  timestamp: {
    type: Date,
    default: Date.now
  },
  updatedBy: {
    type: mongoose.Schema.Types.ObjectId,
    required: true
  },
  notes: String
}, { _id: false });

const referralSchema = new mongoose.Schema({
  // Referral Parties
  referringDoctorId: {
    type: mongoose.Schema.Types.ObjectId,
    required: true,
    index: true
  },
  targetDoctorId: {
    type: mongoose.Schema.Types.ObjectId,
    required: true,
    index: true
  },
  patientId: {
    type: mongoose.Schema.Types.ObjectId,
    required: true,
    index: true
  },

  // Referral Information
  referralDate: {
    type: Date,
    required: true,
    default: Date.now
  },
  reason: {
    type: String,
    required: true,
    trim: true
  },
  urgency: {
    type: String,
    enum: ['routine', 'urgent', 'emergency'],
    default: 'routine'
  },
  specialty: {
    type: String,
    required: true,
    trim: true
  },

  // Medical Context
  diagnosis: {
    type: String,
    trim: true
  },
  symptoms: [{
    type: String,
    trim: true
  }],
  relevantHistory: {
    type: String,
    trim: true
  },
  currentMedications: {
    type: String,
    trim: true
  },
  specificConcerns: {
    type: String,
    trim: true
  },

  // Attached Documents
  attachedDocuments: [{
    type: mongoose.Schema.Types.ObjectId
  }],
  includeFullHistory: {
    type: Boolean,
    default: true
  },

  // Appointment Booking
  appointmentId: {
    type: mongoose.Schema.Types.ObjectId
  },
  isAppointmentBooked: {
    type: Boolean,
    default: false
  },
  preferredDates: [{
    type: Date
  }],

  // Referral Status
  status: {
    type: String,
    enum: ['pending', 'scheduled', 'accepted', 'in_progress', 'completed', 'rejected', 'cancelled'],
    default: 'pending'
  },

  // Status Updates
  statusHistory: [statusHistorySchema],

  // Communication
  referralNotes: {
    type: String,
    trim: true
  },
  responseNotes: {
    type: String,
    trim: true
  },
  feedback: {
    type: String,
    trim: true
  },

  // Rejection Details
  suggestedDoctors: [{
    type: mongoose.Schema.Types.ObjectId
  }],

  // Cancellation
  cancellationReason: {
    type: String,
    trim: true
  },

  // Metadata
  expiryDate: {
    type: Date,
    required: true
  }
}, {
  timestamps: true
});

// Compound Indexes for query optimization
referralSchema.index({ referringDoctorId: 1, referralDate: -1 });
referralSchema.index({ targetDoctorId: 1, status: 1 });
referralSchema.index({ patientId: 1, referralDate: -1 });
referralSchema.index({ status: 1, urgency: 1 });
referralSchema.index({ expiryDate: 1 });

// Pre-save hook: Set expiry date
referralSchema.pre('save', function (next) {
  if (this.isNew && !this.expiryDate) {
    const expiryDays = parseInt(process.env.REFERRAL_EXPIRY_DAYS) || 90;
    this.expiryDate = new Date(Date.now() + expiryDays * 24 * 60 * 60 * 1000);
  }
  next();
});

// Method: Check if referral is expired
referralSchema.methods.isExpired = function () {
  return this.expiryDate < new Date() && this.status === 'pending';
};

// Method: Check if user can view referral
referralSchema.methods.canUserView = function (userId, userRole) {
  if (userRole === 'patient') {
    return this.patientId.toString() === userId.toString();
  }
  if (userRole === 'doctor') {
    return (
      this.referringDoctorId.toString() === userId.toString() ||
      this.targetDoctorId.toString() === userId.toString()
    );
  }
  return false;
};

// Method: Check if user can update referral
referralSchema.methods.canUserUpdate = function (userId) {
  return this.referringDoctorId.toString() === userId.toString();
};

// Method: Check if user can cancel referral
referralSchema.methods.canUserCancel = function (userId, userRole) {
  if (userRole === 'patient') {
    return this.patientId.toString() === userId.toString();
  }
  if (userRole === 'doctor') {
    return this.referringDoctorId.toString() === userId.toString();
  }
  return false;
};

// Method: Add status history entry
referralSchema.methods.addStatusHistory = function (status, updatedBy, notes = '') {
  this.statusHistory.push({
    status,
    timestamp: new Date(),
    updatedBy,
    notes
  });
};

// Static method: Get urgency priority
referralSchema.statics.getUrgencyPriority = function (urgency) {
  const priorities = {
    'emergency': 3,
    'urgent': 2,
    'routine': 1
  };
  return priorities[urgency] || 1;
};

const Referral = mongoose.model('Referral', referralSchema);

export default Referral;
