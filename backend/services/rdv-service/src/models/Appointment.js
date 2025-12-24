import { mongoose } from '../../../../shared/index.js';

const appointmentSchema = new mongoose.Schema({
  patientId: {
    type: mongoose.Schema.Types.ObjectId,
    required: [true, 'Patient ID is required'],
    index: true
  },
  doctorId: {
    type: mongoose.Schema.Types.ObjectId,
    required: [true, 'Doctor ID is required'],
    index: true
  },

  appointmentDate: {
    type: Date,
    required: [true, 'Appointment date is required'],
    index: true
  },
  appointmentTime: {
    type: String,
    required: [true, 'Appointment time is required']
  },
  duration: {
    type: Number,
    default: 30 // minutes
  },

  status: {
    type: String,
    enum: ['pending', 'confirmed', 'rejected', 'cancelled', 'completed', 'no-show'],
    default: 'pending',
    index: true
  },

  reason: {
    type: String,
    trim: true
  },
  notes: {
    type: String,
    trim: true
  },

  // Referral Information
  isReferral: {
    type: Boolean,
    default: false
  },
  referredBy: {
    type: mongoose.Schema.Types.ObjectId,
    default: null
  },
  referralId: {
    type: mongoose.Schema.Types.ObjectId,
    default: null
  },

  // Cancellation/Rejection
  cancellationReason: String,
  cancelledBy: {
    type: String,
    enum: ['patient', 'doctor', null],
    default: null
  },
  cancelledAt: Date,

  rejectionReason: String,
  rejectedAt: Date,

  // Confirmation
  confirmedAt: Date,
  completedAt: Date,

  // Reminders
  reminderSent: {
    type: Boolean,
    default: false
  },
  reminderSentAt: Date,

  // Reschedule Information
  isRescheduled: {
    type: Boolean,
    default: false
  },
  rescheduledBy: {
    type: String,
    enum: ['patient', 'doctor', null],
    default: null
  },
  rescheduledAt: Date,
  previousDate: Date,
  previousTime: String,
  rescheduleReason: String,
  rescheduleCount: {
    type: Number,
    default: 0
  },

  // Pending reschedule request (from patient)
  rescheduleRequest: {
    requestedDate: Date,
    requestedTime: String,
    reason: String,
    requestedAt: Date,
    status: {
      type: String,
      enum: ['pending', 'approved', 'rejected', null],
      default: null
    }
  }

}, {
  timestamps: true
});

// Compound indexes for efficient queries
appointmentSchema.index({ doctorId: 1, appointmentDate: 1, status: 1 });
appointmentSchema.index({ patientId: 1, appointmentDate: 1, status: 1 });
appointmentSchema.index({ appointmentDate: 1, appointmentTime: 1 });

// Virtual for formatted date-time
appointmentSchema.virtual('formattedDateTime').get(function () {
  if (!this.appointmentDate || !this.appointmentTime) return null;
  const date = new Date(this.appointmentDate);
  return `${date.toLocaleDateString()} ${this.appointmentTime}`;
});

// Include virtuals in JSON
appointmentSchema.set('toJSON', { virtuals: true });
appointmentSchema.set('toObject', { virtuals: true });

const Appointment = mongoose.model('Appointment', appointmentSchema);

export default Appointment;
