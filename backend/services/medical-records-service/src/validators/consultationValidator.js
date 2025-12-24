import Joi from 'joi';

const vitalSignsSchema = Joi.object({
  temperature: Joi.number().min(30).max(45),
  bloodPressure: Joi.string().pattern(/^\d{2,3}\/\d{2,3}$/),
  heartRate: Joi.number().min(40).max(200),
  respiratoryRate: Joi.number().min(8).max(40),
  oxygenSaturation: Joi.number().min(0).max(100),
  weight: Joi.number().min(0).max(500),
  height: Joi.number().min(0).max(300)
});

const medicalNoteSchema = Joi.object({
  symptoms: Joi.array().items(Joi.string().trim().max(200)),
  diagnosis: Joi.string().trim().max(500),
  physicalExamination: Joi.string().trim().max(2000),
  vitalSigns: vitalSignsSchema,
  labResults: Joi.string().trim().max(2000),
  additionalNotes: Joi.string().trim().max(2000)
});

const createConsultationSchema = Joi.object({
  appointmentId: Joi.string()
    .pattern(/^[0-9a-fA-F]{24}$/)
    .required()
    .messages({
      'string.pattern.base': 'Invalid appointment ID format',
      'any.required': 'Appointment ID is required'
    }),
  chiefComplaint: Joi.string()
    .trim()
    .max(1000)
    .required()
    .messages({
      'any.required': 'Chief complaint is required',
      'string.max': 'Chief complaint must not exceed 1000 characters'
    }),
  medicalNote: medicalNoteSchema.required(),
  consultationType: Joi.string()
    .valid('in-person', 'follow-up', 'referral')
    .default('in-person'),
  requiresFollowUp: Joi.boolean().default(false),
  followUpDate: Joi.date().min('now').when('requiresFollowUp', {
    is: true,
    then: Joi.required(),
    otherwise: Joi.optional()
  }),
  followUpNotes: Joi.string().trim().max(500),
  isFromReferral: Joi.boolean().default(false),
  referralId: Joi.string().pattern(/^[0-9a-fA-F]{24}$/).when('isFromReferral', {
    is: true,
    then: Joi.required(),
    otherwise: Joi.optional()
  }),
  status: Joi.string().valid('draft', 'completed').default('completed')
});

const updateConsultationSchema = Joi.object({
  medicalNote: medicalNoteSchema,
  requiresFollowUp: Joi.boolean(),
  followUpDate: Joi.date().min('now'),
  followUpNotes: Joi.string().trim().max(500),
  status: Joi.string().valid('draft', 'completed', 'archived')
}).min(1);

const timelineQuerySchema = Joi.object({
  startDate: Joi.date(),
  endDate: Joi.date().min(Joi.ref('startDate')),
  doctorId: Joi.string().pattern(/^[0-9a-fA-F]{24}$/),
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(100).default(50)
});

const searchQuerySchema = Joi.object({
  keyword: Joi.string().trim().min(2).max(100),
  diagnosis: Joi.string().trim().max(200),
  dateFrom: Joi.date(),
  dateTo: Joi.date().min(Joi.ref('dateFrom')),
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(100).default(20)
}).or('keyword', 'diagnosis');

const consultationHistoryQuerySchema = Joi.object({
  startDate: Joi.date(),
  endDate: Joi.date().min(Joi.ref('startDate')),
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(100).default(20)
});

// Validation middleware
export const validateCreateConsultation = (req, res, next) => {
  const { error, value } = createConsultationSchema.validate(req.body, {
    abortEarly: false,
    stripUnknown: true
  });

  if (error) {
    const errors = error.details.map(detail => detail.message);
    return res.status(400).json({
      message: 'Validation error',
      errors
    });
  }

  req.body = value;
  next();
};

export const validateUpdateConsultation = (req, res, next) => {
  const { error, value } = updateConsultationSchema.validate(req.body, {
    abortEarly: false,
    stripUnknown: true
  });

  if (error) {
    const errors = error.details.map(detail => detail.message);
    return res.status(400).json({
      message: 'Validation error',
      errors
    });
  }

  req.body = value;
  next();
};

export const validateTimelineQuery = (req, res, next) => {
  const { error, value } = timelineQuerySchema.validate(req.query, {
    abortEarly: false,
    stripUnknown: true
  });

  if (error) {
    const errors = error.details.map(detail => detail.message);
    return res.status(400).json({
      message: 'Validation error',
      errors
    });
  }

  req.query = value;
  next();
};

export const validateSearchQuery = (req, res, next) => {
  const { error, value } = searchQuerySchema.validate(req.query, {
    abortEarly: false,
    stripUnknown: true
  });

  if (error) {
    const errors = error.details.map(detail => detail.message);
    return res.status(400).json({
      message: 'Validation error',
      errors
    });
  }

  req.query = value;
  next();
};

export const validateConsultationHistoryQuery = (req, res, next) => {
  const { error, value } = consultationHistoryQuerySchema.validate(req.query, {
    abortEarly: false,
    stripUnknown: true
  });

  if (error) {
    const errors = error.details.map(detail => detail.message);
    return res.status(400).json({
      message: 'Validation error',
      errors
    });
  }

  req.query = value;
  next();
};
