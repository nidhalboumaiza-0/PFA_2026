import Joi from 'joi';

// Create Referral Validation
const createReferralSchema = Joi.object({
  patientId: Joi.string().pattern(/^[0-9a-fA-F]{24}$/).required()
    .messages({
      'string.pattern.base': 'Invalid patient ID format',
      'any.required': 'Patient ID is required'
    }),
  targetDoctorId: Joi.string().pattern(/^[0-9a-fA-F]{24}$/).required()
    .messages({
      'string.pattern.base': 'Invalid target doctor ID format',
      'any.required': 'Target doctor ID is required'
    }),
  reason: Joi.string().min(10).max(1000).required()
    .messages({
      'string.min': 'Reason must be at least 10 characters',
      'string.max': 'Reason cannot exceed 1000 characters',
      'any.required': 'Reason for referral is required'
    }),
  urgency: Joi.string().valid('routine', 'urgent', 'emergency').default('routine'),
  specialty: Joi.string().min(2).max(100).required()
    .messages({
      'any.required': 'Target specialty is required'
    }),
  diagnosis: Joi.string().max(500).allow(''),
  symptoms: Joi.array().items(Joi.string().max(100)).max(20),
  relevantHistory: Joi.string().max(2000).allow(''),
  currentMedications: Joi.string().max(1000).allow(''),
  specificConcerns: Joi.string().max(1000).allow(''),
  attachedDocuments: Joi.array().items(
    Joi.string().pattern(/^[0-9a-fA-F]{24}$/)
  ).max(10),
  includeFullHistory: Joi.boolean().default(true),
  preferredDates: Joi.array().items(Joi.date()).max(5),
  referralNotes: Joi.string().max(500).allow('')
});

// Book Appointment for Referral
const bookAppointmentSchema = Joi.object({
  appointmentDate: Joi.date().required()
    .messages({
      'any.required': 'Appointment date is required'
    }),
  appointmentTime: Joi.string().pattern(/^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/).required()
    .messages({
      'string.pattern.base': 'Invalid time format. Use HH:MM format',
      'any.required': 'Appointment time is required'
    }),
  notes: Joi.string().max(500).allow('')
});

// Accept Referral
const acceptReferralSchema = Joi.object({
  responseNotes: Joi.string().max(500).allow('')
});

// Reject Referral
const rejectReferralSchema = Joi.object({
  responseNotes: Joi.string().min(10).max(500).required()
    .messages({
      'string.min': 'Please provide a reason for rejection (at least 10 characters)',
      'any.required': 'Response notes are required for rejection'
    }),
  suggestedDoctors: Joi.array().items(
    Joi.string().pattern(/^[0-9a-fA-F]{24}$/)
  ).max(5)
});

// Complete Referral
const completeReferralSchema = Joi.object({
  feedback: Joi.string().min(10).max(1000).required()
    .messages({
      'string.min': 'Feedback must be at least 10 characters',
      'any.required': 'Feedback is required to complete referral'
    }),
  consultationCreated: Joi.boolean().default(false)
});

// Cancel Referral
const cancelReferralSchema = Joi.object({
  cancellationReason: Joi.string().min(10).max(500).required()
    .messages({
      'string.min': 'Cancellation reason must be at least 10 characters',
      'any.required': 'Cancellation reason is required'
    })
});

// Search Specialists Query
const searchSpecialistsSchema = Joi.object({
  specialty: Joi.string().min(2).max(100).required()
    .messages({
      'any.required': 'Specialty is required for search'
    }),
  city: Joi.string().max(100),
  latitude: Joi.number().min(-90).max(90),
  longitude: Joi.number().min(-180).max(180),
  radius: Joi.number().min(1).max(100).default(10),
  availableAfter: Joi.date(),
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(50).default(20)
});

// Get Received Referrals Query
const getReceivedReferralsSchema = Joi.object({
  status: Joi.string().valid('pending', 'scheduled', 'accepted', 'in_progress', 'completed', 'rejected', 'cancelled'),
  urgency: Joi.string().valid('routine', 'urgent', 'emergency'),
  startDate: Joi.date(),
  endDate: Joi.date(),
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(100).default(20)
});

// Get Sent Referrals Query
const getSentReferralsSchema = Joi.object({
  status: Joi.string().valid('pending', 'scheduled', 'accepted', 'in_progress', 'completed', 'rejected', 'cancelled'),
  patientId: Joi.string().pattern(/^[0-9a-fA-F]{24}$/),
  specialty: Joi.string().max(100),
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(100).default(20)
});

// Validation Middleware
export const validateCreateReferral = (req, res, next) => {
  const { error } = createReferralSchema.validate(req.body, { abortEarly: false });
  if (error) {
    return res.status(400).json({
      message: error.details.map(detail => detail.message).join(', ')
    });
  }
  next();
};

export const validateBookAppointment = (req, res, next) => {
  const { error } = bookAppointmentSchema.validate(req.body, { abortEarly: false });
  if (error) {
    return res.status(400).json({
      message: error.details.map(detail => detail.message).join(', ')
    });
  }
  next();
};

export const validateAcceptReferral = (req, res, next) => {
  const { error } = acceptReferralSchema.validate(req.body, { abortEarly: false });
  if (error) {
    return res.status(400).json({
      message: error.details.map(detail => detail.message).join(', ')
    });
  }
  next();
};

export const validateRejectReferral = (req, res, next) => {
  const { error } = rejectReferralSchema.validate(req.body, { abortEarly: false });
  if (error) {
    return res.status(400).json({
      message: error.details.map(detail => detail.message).join(', ')
    });
  }
  next();
};

export const validateCompleteReferral = (req, res, next) => {
  const { error } = completeReferralSchema.validate(req.body, { abortEarly: false });
  if (error) {
    return res.status(400).json({
      message: error.details.map(detail => detail.message).join(', ')
    });
  }
  next();
};

export const validateCancelReferral = (req, res, next) => {
  const { error } = cancelReferralSchema.validate(req.body, { abortEarly: false });
  if (error) {
    return res.status(400).json({
      message: error.details.map(detail => detail.message).join(', ')
    });
  }
  next();
};

export const validateSearchSpecialists = (req, res, next) => {
  const { error } = searchSpecialistsSchema.validate(req.query, { abortEarly: false });
  if (error) {
    return res.status(400).json({
      message: error.details.map(detail => detail.message).join(', ')
    });
  }
  next();
};

export const validateGetReceivedReferrals = (req, res, next) => {
  const { error } = getReceivedReferralsSchema.validate(req.query, { abortEarly: false });
  if (error) {
    return res.status(400).json({
      message: error.details.map(detail => detail.message).join(', ')
    });
  }
  next();
};

export const validateGetSentReferrals = (req, res, next) => {
  const { error } = getSentReferralsSchema.validate(req.query, { abortEarly: false });
  if (error) {
    return res.status(400).json({
      message: error.details.map(detail => detail.message).join(', ')
    });
  }
  next();
};
