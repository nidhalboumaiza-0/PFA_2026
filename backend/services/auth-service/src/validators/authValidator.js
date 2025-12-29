import Joi from 'joi';

/**
 * Registration validation
 */
const registerSchema = Joi.object({
  email: Joi.string().email().required().messages({
    'string.email': 'Please enter a valid email address (e.g., name@example.com).',
    'string.empty': 'Email address is required.',
    'any.required': 'Email address is required.'
  }),
  password: Joi.string()
    .min(8)
    .pattern(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
    .required()
    .messages({
      'string.min': 'Password must be at least 8 characters long.',
      'string.pattern.base': 'Password must include at least one uppercase letter, one lowercase letter, and one number.',
      'string.empty': 'Password is required.',
      'any.required': 'Password is required.'
    }),
  role: Joi.string()
    .valid('patient', 'doctor')
    .required()
    .messages({
      'any.only': 'Please select a valid role: patient or doctor.',
      'string.empty': 'Please select your role.',
      'any.required': 'Please select your role.'
    }),
  profileData: Joi.object().optional()
});

/**
 * Login validation
 */
const loginSchema = Joi.object({
  email: Joi.string().email().required().messages({
    'string.email': 'Please enter a valid email address.',
    'string.empty': 'Email address is required.',
    'any.required': 'Email address is required.'
  }),
  password: Joi.string().required().messages({
    'string.empty': 'Password is required.',
    'any.required': 'Password is required.'
  })
});

/**
 * Refresh token validation
 */
const refreshTokenSchema = Joi.object({
  refreshToken: Joi.string().required().messages({
    'string.empty': 'Refresh token is required.',
    'any.required': 'Refresh token is required.'
  })
});

/**
 * Forgot password validation
 */
const forgotPasswordSchema = Joi.object({
  email: Joi.string().email().required().messages({
    'string.email': 'Please enter a valid email address.',
    'string.empty': 'Email address is required.',
    'any.required': 'Email address is required.'
  })
});

/**
 * Reset password validation
 */
const resetPasswordSchema = Joi.object({
  newPassword: Joi.string()
    .min(8)
    .pattern(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
    .required()
    .messages({
      'string.min': 'Your new password must be at least 8 characters long.',
      'string.pattern.base': 'Your new password must include at least one uppercase letter, one lowercase letter, and one number.',
      'string.empty': 'Please enter a new password.',
      'any.required': 'Please enter a new password.'
    })
});

/**
 * Change password validation
 */
const changePasswordSchema = Joi.object({
  currentPassword: Joi.string().required().messages({
    'string.empty': 'Please enter your current password.',
    'any.required': 'Please enter your current password.'
  }),
  newPassword: Joi.string()
    .min(8)
    .pattern(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
    .required()
    .invalid(Joi.ref('currentPassword'))
    .messages({
      'string.min': 'Your new password must be at least 8 characters long.',
      'string.pattern.base': 'Your new password must include at least one uppercase letter, one lowercase letter, and one number.',
      'string.empty': 'Please enter a new password.',
      'any.required': 'Please enter a new password.',
      'any.invalid': 'Your new password must be different from your current password.'
    })
});

/**
 * Resend verification validation
 */
const resendVerificationSchema = Joi.object({
  email: Joi.string().email().required().messages({
    'string.email': 'Please enter a valid email address.',
    'string.empty': 'Email address is required.',
    'any.required': 'Email address is required.'
  })
});

/**
 * Validate request data with standardized error format
 */
const validate = (schema) => {
  return (req, res, next) => {
    const { error } = schema.validate(req.body, { abortEarly: false });
    
    if (error) {
      const errors = error.details.map(detail => ({
        field: detail.path.join('.'),
        message: detail.message
      }));
      
      return res.status(400).json({
        success: false,
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Please check the form and correct the errors below.',
          details: { errors }
        }
      });
    }
    
    next();
  };
};

export const validateRegister = validate(registerSchema);
export const validateLogin = validate(loginSchema);
export const validateRefreshToken = validate(refreshTokenSchema);
export const validateForgotPassword = validate(forgotPasswordSchema);
export const validateResetPassword = validate(resetPasswordSchema);
export const validateChangePassword = validate(changePasswordSchema);
export const validateResendVerification = validate(resendVerificationSchema);
