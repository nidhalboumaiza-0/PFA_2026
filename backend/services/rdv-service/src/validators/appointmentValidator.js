import Joi from 'joi';

/**
 * Set availability validation
 */
const setAvailabilitySchema = Joi.object({
  date: Joi.date().min('now').required().messages({
    'date.min': 'Date must be today or in the future'
  }),
  slots: Joi.array().items(
    Joi.object({
      time: Joi.string().pattern(/^([01]\d|2[0-3]):([0-5]\d)$/).required().messages({
        'string.pattern.base': 'Time must be in HH:MM format (e.g., 14:30)'
      })
    })
  ).min(1).required(),
  isAvailable: Joi.boolean().default(true),
  specialNotes: Joi.string().allow('', null)
});

/**
 * Request appointment validation
 */
const requestAppointmentSchema = Joi.object({
  doctorId: Joi.string().pattern(/^[0-9a-fA-F]{24}$/).required().messages({
    'string.pattern.base': 'Invalid doctor ID format'
  }),
  appointmentDate: Joi.date().min('now').required().messages({
    'date.min': 'Appointment date must be in the future'
  }),
  appointmentTime: Joi.string().pattern(/^([01]\d|2[0-3]):([0-5]\d)$/).required().messages({
    'string.pattern.base': 'Time must be in HH:MM format'
  }),
  reason: Joi.string().max(500).required().messages({
    'any.required': 'Reason for appointment is required'
  })
});

/**
 * Confirm appointment validation
 */
const confirmAppointmentSchema = Joi.object({
  notes: Joi.string().max(1000).allow('', null)
});

/**
 * Reject appointment validation
 */
const rejectAppointmentSchema = Joi.object({
  rejectionReason: Joi.string().max(500).required().messages({
    'any.required': 'Rejection reason is required'
  })
});

/**
 * Cancel appointment validation
 */
const cancelAppointmentSchema = Joi.object({
  cancellationReason: Joi.string().max(500).required().messages({
    'any.required': 'Cancellation reason is required'
  })
});

/**
 * Referral booking validation
 */
const referralBookingSchema = Joi.object({
  patientId: Joi.string().pattern(/^[0-9a-fA-F]{24}$/).required(),
  targetDoctorId: Joi.string().pattern(/^[0-9a-fA-F]{24}$/).required(),
  appointmentDate: Joi.date().min('now').required(),
  appointmentTime: Joi.string().pattern(/^([01]\d|2[0-3]):([0-5]\d)$/).required(),
  referralId: Joi.string().pattern(/^[0-9a-fA-F]{24}$/).required(),
  notes: Joi.string().max(1000).allow('', null)
});

/**
 * Validate request data
 */
const validate = (schema) => {
  return (req, res, next) => {
    const { error } = schema.validate(req.body, { abortEarly: false });
    
    if (error) {
      const errors = error.details.map(detail => detail.message);
      return res.status(400).json({
        message: 'Validation error',
        errors
      });
    }
    
    next();
  };
};

/**
 * Bulk set availability validation (for applying templates)
 */
const bulkSetAvailabilitySchema = Joi.object({
  availabilities: Joi.array().items(
    Joi.object({
      date: Joi.date().min('now').required(),
      slots: Joi.array().items(
        Joi.object({
          time: Joi.string().pattern(/^([01]\d|2[0-3]):([0-5]\d)$/).required()
        })
      ).min(1).required(),
      isAvailable: Joi.boolean().default(true),
      specialNotes: Joi.string().allow('', null)
    })
  ).min(1).max(31).required().messages({
    'array.max': 'Cannot set availability for more than 31 days at once'
  }),
  skipExisting: Joi.boolean().default(true)
});

export const validateSetAvailability = validate(setAvailabilitySchema);
export const validateBulkSetAvailability = validate(bulkSetAvailabilitySchema);
export const validateRequestAppointment = validate(requestAppointmentSchema);
export const validateConfirmAppointment = validate(confirmAppointmentSchema);
export const validateRejectAppointment = validate(rejectAppointmentSchema);
export const validateCancelAppointment = validate(cancelAppointmentSchema);
export const validateReferralBooking = validate(referralBookingSchema);
