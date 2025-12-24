import { mongoose } from '../../../../shared/index.js';

const timeSlotSchema = new mongoose.Schema({
  doctorId: {
    type: mongoose.Schema.Types.ObjectId,
    required: [true, 'Doctor ID is required'],
    index: true
  },
  date: {
    type: Date,
    required: [true, 'Date is required'],
    index: true
  },

  slots: [{
    time: {
      type: String,
      required: true
    },
    isBooked: {
      type: Boolean,
      default: false
    },
    appointmentId: {
      type: mongoose.Schema.Types.ObjectId,
      default: null
    }
  }],

  isAvailable: {
    type: Boolean,
    default: true
  },
  specialNotes: {
    type: String,
    trim: true
  }

}, {
  timestamps: true
});

// Compound unique index on doctorId + date
timeSlotSchema.index({ doctorId: 1, date: 1 }, { unique: true });

// Method to check if a specific time slot is available
timeSlotSchema.methods.isSlotAvailable = function (time) {
  if (!this.isAvailable) return false;

  const slot = this.slots.find(s => s.time === time);
  return slot && !slot.isBooked;
};

// Method to book a slot
timeSlotSchema.methods.bookSlot = function (time, appointmentId) {
  const slot = this.slots.find(s => s.time === time);
  if (slot) {
    slot.isBooked = true;
    slot.appointmentId = appointmentId;
  }
  return this.save();
};

// Method to free a slot
timeSlotSchema.methods.freeSlot = function (time) {
  const slot = this.slots.find(s => s.time === time);
  if (slot) {
    slot.isBooked = false;
    slot.appointmentId = null;
  }
  return this.save();
};

const TimeSlot = mongoose.model('TimeSlot', timeSlotSchema);

export default TimeSlot;
