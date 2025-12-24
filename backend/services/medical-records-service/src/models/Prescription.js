import { mongoose } from '../../../../shared/index.js';

const medicationSchema = new mongoose.Schema({
  medicationName: {
    type: String,
    required: true,
    trim: true
  },
  dosage: {
    type: String,
    required: true,
    trim: true
  },
  form: {
    type: String,
    trim: true,
    enum: ['tablet', 'capsule', 'syrup', 'injection', 'cream', 'drops', 'inhaler', 'patch', 'other']
  },
  frequency: {
    type: String,
    required: true,
    trim: true
  },
  duration: {
    type: String,
    required: true,
    trim: true
  },
  instructions: {
    type: String,
    trim: true,
    maxlength: 500
  },
  quantity: {
    type: Number,
    min: 0
  },
  notes: {
    type: String,
    trim: true,
    maxlength: 500
  }
}, { _id: false });

const modificationHistorySchema = new mongoose.Schema({
  modifiedAt: {
    type: Date,
    default: Date.now
  },
  modifiedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Doctor'
  },
  changeType: {
    type: String,
    enum: ['created', 'updated', 'manual_locked', 'auto_locked'],
    required: true
  },
  changes: {
    type: mongoose.Schema.Types.Mixed
  },
  previousData: {
    type: mongoose.Schema.Types.Mixed
  }
}, { _id: false });

const prescriptionSchema = new mongoose.Schema({
  consultationId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Consultation',
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
  prescriptionDate: {
    type: Date,
    default: Date.now,
    required: true
  },
  medications: {
    type: [medicationSchema],
    validate: {
      validator: function (medications) {
        return medications && medications.length > 0;
      },
      message: 'Prescription must have at least one medication'
    }
  },
  generalInstructions: {
    type: String,
    trim: true,
    maxlength: 2000
  },
  specialWarnings: {
    type: String,
    trim: true,
    maxlength: 1000
  },
  isLocked: {
    type: Boolean,
    default: false,
    index: true
  },
  lockedAt: {
    type: Date
  },
  canEditUntil: {
    type: Date,
    index: true
  },
  modificationHistory: {
    type: [modificationHistorySchema],
    default: []
  },
  status: {
    type: String,
    enum: ['active', 'completed', 'cancelled'],
    default: 'active',
    index: true
  },
  pharmacyName: {
    type: String,
    trim: true
  },
  pharmacyAddress: {
    type: String,
    trim: true
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Doctor',
    required: true
  }
}, {
  timestamps: true
});

// Compound Indexes
prescriptionSchema.index({ patientId: 1, prescriptionDate: -1 });
prescriptionSchema.index({ doctorId: 1, prescriptionDate: -1 });
prescriptionSchema.index({ patientId: 1, status: 1, prescriptionDate: -1 });
prescriptionSchema.index({ isLocked: 1, canEditUntil: 1 });

// Pre-save hook to calculate lock time for new prescriptions
prescriptionSchema.pre('save', function (next) {
  if (this.isNew) {
    const oneHourLater = new Date(this.createdAt.getTime() + 60 * 60 * 1000);
    this.canEditUntil = oneHourLater;
    this.lockedAt = oneHourLater;

    // Add creation to modification history
    this.modificationHistory.push({
      modifiedAt: this.createdAt,
      modifiedBy: this.createdBy,
      changeType: 'created',
      changes: { status: 'created' }
    });
  }
  next();
});

// Method to check if prescription is editable
prescriptionSchema.methods.isEditable = function () {
  return !this.isLocked && new Date() < this.canEditUntil;
};

// Method to auto-lock if time expired
prescriptionSchema.methods.checkAndLock = async function () {
  if (!this.isLocked && new Date() >= this.canEditUntil) {
    this.isLocked = true;
    this.modificationHistory.push({
      modifiedAt: new Date(),
      changeType: 'auto_locked',
      changes: { isLocked: true }
    });
    await this.save();
    return true;
  }
  return false;
};

// Method to manually lock prescription
prescriptionSchema.methods.manualLock = async function (doctorId) {
  if (this.isLocked) {
    throw new Error('Prescription is already locked');
  }

  this.isLocked = true;
  this.lockedAt = new Date();
  this.modificationHistory.push({
    modifiedAt: new Date(),
    modifiedBy: doctorId,
    changeType: 'manual_locked',
    changes: { isLocked: true }
  });

  await this.save();
  return this;
};

// Method to calculate remaining edit time in minutes
prescriptionSchema.methods.getRemainingEditTime = function () {
  if (this.isLocked) {
    return 0;
  }

  const now = new Date();
  const remainingMs = this.canEditUntil.getTime() - now.getTime();

  if (remainingMs <= 0) {
    return 0;
  }

  return Math.ceil(remainingMs / (1000 * 60)); // Convert to minutes
};

// Virtual for medication summary
prescriptionSchema.virtual('medicationSummary').get(function () {
  return this.medications.map(m => m.medicationName).join(', ');
});

// Virtual for medication count
prescriptionSchema.virtual('medicationCount').get(function () {
  return this.medications.length;
});

const Prescription = mongoose.model('Prescription', prescriptionSchema);

export default Prescription;
