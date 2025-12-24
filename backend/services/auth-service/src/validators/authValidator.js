import Joi from 'joi';

/**
 * Registration validation
 */
const registerSchema = Joi.object({
  email: Joi.string().email().required().messages({
    'string.email': 'Please provide a valid email address',
    'any.required': 'Email is required'
  }),
  password: Joi.string()
    .min(8)
    .pattern(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
    .required()
    .messages({
      'string.min': 'Password must be at least 8 characters',
      'string.pattern.base': 'Password must contain at least one uppercase letter, one lowercase letter, and one number',
      'any.required': 'Password is required'
    }),
  role: Joi.string()
    .valid('patient', 'doctor')
    .required()
    .messages({
      'any.only': 'Role must be either patient or doctor',
      'any.required': 'Role is required'
    }),
  profileData: Joi.object().optional()
});

/**
 * Login validation
 */
const loginSchema = Joi.object({
  email: Joi.string().email().required(),
  password: Joi.string().required()
});

/**
 * Refresh token validation
 */
const refreshTokenSchema = Joi.object({
  refreshToken: Joi.string().required()
});

/**
 * Forgot password validation
 */
const forgotPasswordSchema = Joi.object({
  email: Joi.string().email().required()
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
      'string.min': 'Password must be at least 8 characters',
      'string.pattern.base': 'Password must contain at least one uppercase letter, one lowercase letter, and one number'
    })
});

/**
 * Change password validation
 */
const changePasswordSchema = Joi.object({
  currentPassword: Joi.string().required(),
  newPassword: Joi.string()
    .min(8)
    .pattern(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
    .required()
    .invalid(Joi.ref('currentPassword'))
    .messages({
      'string.min': 'Password must be at least 8 characters',
      'string.pattern.base': 'Password must contain at least one uppercase letter, one lowercase letter, and one number',
      'any.invalid': 'New password must be different from current password'
    })
});

/**
 * Resend verification validation
 */
const resendVerificationSchema = Joi.object({
  email: Joi.string().email().required()
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

export const validateRegister = validate(registerSchema);
export const validateLogin = validate(loginSchema);
export const validateRefreshToken = validate(refreshTokenSchema);
export const validateForgotPassword = validate(forgotPasswordSchema);
export const validateResetPassword = validate(resetPasswordSchema);
export const validateChangePassword = validate(changePasswordSchema);
export const validateResendVerification = validate(resendVerificationSchema);
