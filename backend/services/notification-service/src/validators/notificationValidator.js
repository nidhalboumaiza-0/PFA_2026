import Joi from 'joi';

// Get notifications validator
export const getNotificationsSchema = Joi.object({
  isRead: Joi.boolean().optional(),
  type: Joi.string()
    .valid(
      'appointment_confirmed',
      'appointment_rejected',
      'appointment_reminder',
      'appointment_cancelled',
      'new_message',
      'referral_received',
      'referral_scheduled',
      'consultation_created',
      'prescription_created',
      'document_uploaded',
      'system_alert'
    )
    .optional(),
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(100).default(20),
});

// Update preferences validator
export const updatePreferencesSchema = Joi.object({
  preferences: Joi.object({
    appointmentConfirmed: Joi.object({
      push: Joi.boolean().required(),
      email: Joi.boolean().required(),
      inApp: Joi.boolean().required(),
    }).optional(),
    appointmentReminder: Joi.object({
      push: Joi.boolean().required(),
      email: Joi.boolean().required(),
      inApp: Joi.boolean().required(),
    }).optional(),
    appointmentCancelled: Joi.object({
      push: Joi.boolean().required(),
      email: Joi.boolean().required(),
      inApp: Joi.boolean().required(),
    }).optional(),
    newMessage: Joi.object({
      push: Joi.boolean().required(),
      email: Joi.boolean().required(),
      inApp: Joi.boolean().required(),
    }).optional(),
    referral: Joi.object({
      push: Joi.boolean().required(),
      email: Joi.boolean().required(),
      inApp: Joi.boolean().required(),
    }).optional(),
    prescription: Joi.object({
      push: Joi.boolean().required(),
      email: Joi.boolean().required(),
      inApp: Joi.boolean().required(),
    }).optional(),
    systemAlert: Joi.object({
      push: Joi.boolean().required(),
      email: Joi.boolean().required(),
      inApp: Joi.boolean().required(),
    }).optional(),
  }).required(),
});

// Register device validator
export const registerDeviceSchema = Joi.object({
  oneSignalPlayerId: Joi.string().required().messages({
    'any.required': 'OneSignal Player ID is required',
    'string.empty': 'OneSignal Player ID cannot be empty',
  }),
  deviceType: Joi.string().valid('mobile', 'web').required().messages({
    'any.required': 'Device type is required',
    'any.only': 'Device type must be either mobile or web',
  }),
  platform: Joi.string().valid('android', 'ios', 'web').required().messages({
    'any.required': 'Platform is required',
    'any.only': 'Platform must be android, ios, or web',
  }),
});

// Mark as read validator
export const markAsReadSchema = Joi.object({
  notificationId: Joi.string()
    .pattern(/^[0-9a-fA-F]{24}$/)
    .required()
    .messages({
      'any.required': 'Notification ID is required',
      'string.pattern.base': 'Invalid notification ID format',
    }),
});

// Validation middleware
export const validate = (schema) => {
  return (req, res, next) => {
    const dataToValidate = req.method === 'GET' ? req.query : req.body;

    const { error, value } = schema.validate(dataToValidate, {
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
