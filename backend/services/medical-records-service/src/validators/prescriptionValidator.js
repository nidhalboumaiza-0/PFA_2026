import Joi from 'joi';

const medicationSchema = Joi.object({
  medicationName: Joi.string().trim().required().max(200).messages({
    'any.required': 'Medication name is required',
    'string.empty': 'Medication name cannot be empty'
  }),
  dosage: Joi.string().trim().required().max(100).messages({
    'any.required': 'Dosage is required'
  }),
  form: Joi.string().trim().valid(
    'tablet', 'capsule', 'syrup', 'injection', 'cream', 'drops', 'inhaler', 'patch', 'other'
  ),
  frequency: Joi.string().trim().required().max(200).messages({
    'any.required': 'Frequency is required'
  }),
  duration: Joi.string().trim().required().max(100).messages({
    'any.required': 'Duration is required'
  }),
  instructions: Joi.string().trim().max(500),
  quantity: Joi.number().min(0).max(10000),
  notes: Joi.string().trim().max(500)
});

const createPrescriptionSchema = Joi.object({
  consultationId: Joi.string()
    .pattern(/^[0-9a-fA-F]{24}$/)
    .required()
    .messages({
      'string.pattern.base': 'Invalid consultation ID format',
      'any.required': 'Consultation ID is required'
    }),
  medications: Joi.array()
    .items(medicationSchema)
    .min(1)
    .required()
    .messages({
      'array.min': 'At least one medication is required',
      'any.required': 'Medications array is required'
    }),
  generalInstructions: Joi.string().trim().max(2000),
  specialWarnings: Joi.string().trim().max(1000),
  pharmacyName: Joi.string().trim().max(200),
  pharmacyAddress: Joi.string().trim().max(500),
  status: Joi.string().valid('active', 'completed', 'cancelled').default('active')
});

const updatePrescriptionSchema = Joi.object({
  medications: Joi.array()
    .items(medicationSchema)
    .min(1)
    .messages({
      'array.min': 'At least one medication is required'
    }),
  generalInstructions: Joi.string().trim().max(2000),
  specialWarnings: Joi.string().trim().max(1000),
  pharmacyName: Joi.string().trim().max(200),
  pharmacyAddress: Joi.string().trim().max(500),
  status: Joi.string().valid('active', 'completed', 'cancelled')
}).min(1).messages({
  'object.min': 'At least one field must be provided for update'
});

const prescriptionQuerySchema = Joi.object({
  startDate: Joi.date(),
  endDate: Joi.date().min(Joi.ref('startDate')),
  status: Joi.string().valid('active', 'completed', 'cancelled', 'all').default('all'),
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(100).default(20)
});

const myPrescriptionsQuerySchema = Joi.object({
  status: Joi.string().valid('active', 'completed', 'cancelled', 'all').default('all'),
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(100).default(20)
});

// Validation middleware
export const validateCreatePrescription = (req, res, next) => {
  const { error, value } = createPrescriptionSchema.validate(req.body, {
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

export const validateUpdatePrescription = (req, res, next) => {
  const { error, value } = updatePrescriptionSchema.validate(req.body, {
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

export const validatePrescriptionQuery = (req, res, next) => {
  const { error, value } = prescriptionQuerySchema.validate(req.query, {
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

export const validateMyPrescriptionsQuery = (req, res, next) => {
  const { error, value } = myPrescriptionsQuerySchema.validate(req.query, {
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
