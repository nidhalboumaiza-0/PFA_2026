import Joi from 'joi';

// Get audit logs validator
export const getAuditLogsSchema = Joi.object({
  actionCategory: Joi.string()
    .valid(
      'authentication',
      'user_management',
      'appointment',
      'consultation',
      'prescription',
      'document',
      'referral',
      'message',
      'system'
    )
    .optional(),
  performedBy: Joi.string()
    .pattern(/^[0-9a-fA-F]{24}$/)
    .optional(),
  patientId: Joi.string()
    .pattern(/^[0-9a-fA-F]{24}$/)
    .optional(),
  resourceType: Joi.string().optional(),
  severity: Joi.string().valid('info', 'warning', 'critical').optional(),
  status: Joi.string().valid('success', 'failed', 'blocked').optional(),
  isSecurityRelevant: Joi.boolean().optional(),
  isComplianceRelevant: Joi.boolean().optional(),
  requiresReview: Joi.boolean().optional(),
  startDate: Joi.date().iso().optional(),
  endDate: Joi.date().iso().optional(),
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(500).default(50),
});

// Get user activity validator
export const getUserActivitySchema = Joi.object({
  userId: Joi.string()
    .pattern(/^[0-9a-fA-F]{24}$/)
    .required()
    .messages({
      'string.pattern.base': 'Invalid user ID format',
      'any.required': 'User ID is required',
    }),
  startDate: Joi.date().iso().optional(),
  endDate: Joi.date().iso().optional(),
  actionCategory: Joi.string()
    .valid(
      'authentication',
      'user_management',
      'appointment',
      'consultation',
      'prescription',
      'document',
      'referral',
      'message',
      'system'
    )
    .optional(),
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(500).default(50),
});

// Get patient access log validator
export const getPatientAccessLogSchema = Joi.object({
  patientId: Joi.string()
    .pattern(/^[0-9a-fA-F]{24}$/)
    .required()
    .messages({
      'string.pattern.base': 'Invalid patient ID format',
      'any.required': 'Patient ID is required',
    }),
  startDate: Joi.date().iso().optional(),
  endDate: Joi.date().iso().optional(),
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(500).default(50),
});

// Get security events validator
export const getSecurityEventsSchema = Joi.object({
  severity: Joi.string().valid('warning', 'critical').optional(),
  requiresReview: Joi.boolean().optional(),
  startDate: Joi.date().iso().optional(),
  endDate: Joi.date().iso().optional(),
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(500).default(20),
});

// Get statistics validator
export const getStatisticsSchema = Joi.object({
  startDate: Joi.date().iso().optional(),
  endDate: Joi.date().iso().optional(),
});

// Mark as reviewed validator
export const markAsReviewedSchema = Joi.object({
  reviewNotes: Joi.string().max(500).required().messages({
    'any.required': 'Review notes are required',
    'string.max': 'Review notes must not exceed 500 characters',
  }),
});

// Export logs validator
export const exportLogsSchema = Joi.object({
  format: Joi.string().valid('csv', 'json').default('csv'),
  actionCategory: Joi.string()
    .valid(
      'authentication',
      'user_management',
      'appointment',
      'consultation',
      'prescription',
      'document',
      'referral',
      'message',
      'system'
    )
    .optional(),
  startDate: Joi.date().iso().optional(),
  endDate: Joi.date().iso().optional(),
  limit: Joi.number().integer().min(1).max(10000).default(1000),
});

// Validation middleware
export const validate = (schema) => {
  return (req, res, next) => {
    const dataToValidate = req.method === 'GET' ? req.query : req.body;

    // Merge path params if they exist
    const allData = { ...dataToValidate, ...req.params };

    const { error, value } = schema.validate(allData, {
      abortEarly: false,
      stripUnknown: true,
    });

    if (error) {
      const errors = error.details.map((detail) => ({
        field: detail.path.join('.'),
        message: detail.message,
      }));

      return res.status(400).json({
        success: false,
        message: 'Validation error',
        errors,
      });
    }

    // Replace req data with validated data
    if (req.method === 'GET') {
      req.query = value;
    } else {
      req.body = value;
    }

    next();
  };
};
