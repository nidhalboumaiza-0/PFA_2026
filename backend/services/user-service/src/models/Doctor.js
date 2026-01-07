import { mongoose } from '../../../../shared/index.js';

const doctorSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    required: true,
    unique: true,
    index: true
  },
  email: {
    type: String,
    trim: true,
    lowercase: true
  },
  firstName: {
    type: String,
    required: [true, 'First name is required'],
    trim: true
  },
  lastName: {
    type: String,
    required: [true, 'Last name is required'],
    trim: true
  },
  specialty: {
    type: String,
    required: [true, 'Specialty is required'],
    trim: true
  },
  subSpecialty: {
    type: String,
    trim: true
  },
  phone: {
    type: String,
    required: [true, 'Phone number is required'],
    trim: true
  },
  profilePhoto: {
    type: String,
    default: null
  },
  licenseNumber: {
    type: String,
    required: [true, 'License number is required'],
    unique: true,
    trim: true
  },
  yearsOfExperience: {
    type: Number,
    default: 0
  },
  education: [{
    degree: String,
    institution: String,
    year: Number
  }],
  languages: {
    type: [String],
    default: []
  },

  // Clinic/Practice Information
  clinicName: {
    type: String,
    trim: true
  },
  clinicAddress: {
    street: String,
    city: {
      type: String,
      required: [true, 'City is required']
    },
    state: String,
    zipCode: String,
    country: {
      type: String,
      required: [true, 'Country is required']
    },
    coordinates: {
      type: {
        type: String,
        enum: ['Point'],
        default: 'Point'
      },
      coordinates: {
        type: [Number], // [longitude, latitude]
        required: true
      }
    }
  },

  // Professional Details
  about: {
    type: String,
    maxlength: 1000
  },
  consultationFee: {
    type: Number,
    default: 0
  },
  acceptsInsurance: {
    type: Boolean,
    default: false
  },
  rating: {
    type: Number,
    default: 0,
    min: 0,
    max: 5
  },
  totalReviews: {
    type: Number,
    default: 0
  },

  // Availability
  workingHours: [{
    day: {
      type: String,
      enum: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
    },
    isAvailable: {
      type: Boolean,
      default: false
    },
    slots: [{
      startTime: String, // "09:00"
      endTime: String    // "17:00"
    }]
  }],

  isVerified: {
    type: Boolean,
    default: false
  },
  isActive: {
    type: Boolean,
    default: true
  },
  oneSignalPlayerId: {
    type: String,
    default: null
  }
}, {
  timestamps: true
});

// Create 2dsphere index for geospatial queries
doctorSchema.index({ 'clinicAddress.coordinates': '2dsphere' });

// Index for text search
doctorSchema.index({
  firstName: 'text',
  lastName: 'text',
  clinicName: 'text',
  specialty: 'text'
});

// Virtual for full name
doctorSchema.virtual('fullName').get(function () {
  return `Dr. ${this.firstName} ${this.lastName}`;
});

// Include virtuals in JSON
doctorSchema.set('toJSON', { virtuals: true });
doctorSchema.set('toObject', { virtuals: true });

const Doctor = mongoose.model('Doctor', doctorSchema);

export default Doctor;
