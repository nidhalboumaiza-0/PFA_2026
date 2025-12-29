import User from '../models/User.js';
import { 
  kafkaProducer, 
  TOPICS, 
  createEvent,
  createSession,
  deleteSession,
  getUserSessions,
  deleteAllUserSessions,
  validateSession
} from '../../../../shared/index.js';
import * as emailService from '../services/emailService.js';
import jwt from 'jsonwebtoken';
import crypto from 'crypto';

/**
 * Standardized error response helper
 * @param {Response} res - Express response object
 * @param {number} statusCode - HTTP status code
 * @param {string} code - Error code for frontend handling
 * @param {string} message - User-friendly message
 * @param {object} details - Additional error details (optional)
 */
const sendError = (res, statusCode, code, message, details = null) => {
  const response = {
    success: false,
    error: {
      code,
      message,
      ...(details && { details })
    }
  };
  return res.status(statusCode).json(response);
};

/**
 * Standardized success response helper
 */
const sendSuccess = (res, statusCode, message, data = null) => {
  const response = {
    success: true,
    message,
    ...(data && { data })
  };
  return res.status(statusCode).json(response);
};

/**
 * Register new user
 * POST /api/v1/auth/register
 */
export const register = async (req, res, next) => {
  try {
    const { email, password, role, profileData } = req.body;

    // Check if user already exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return sendError(res, 409, 'EMAIL_EXISTS', 
        'This email is already registered. Please use a different email or try logging in.');
    }

    // Create user
    const user = await User.create({
      email,
      password,
      role,
      isEmailVerified: false
    });

    // Generate email verification token
    const verificationToken = user.generateEmailVerificationToken();
    await user.save();

    // Send verification email
    try {
      await emailService.sendVerificationEmail(email, verificationToken);
    } catch (emailError) {
      console.error('Failed to send verification email:', emailError);
      // Don't fail registration if email fails
    }

    // Publish Kafka event
    await kafkaProducer.sendEvent(
      TOPICS.AUTH.USER_REGISTERED,
      createEvent('auth.user.registered', {
        userId: user._id.toString(),
        email: user.email,
        role: user.role,
        profileData
      })
    );

    return sendSuccess(res, 201, 
      'Registration successful! Please check your email to verify your account.', {
      user: {
        id: user._id,
        email: user.email,
        role: user.role,
        isEmailVerified: user.isEmailVerified
      }
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Login user
 * POST /api/v1/auth/login
 */
export const login = async (req, res, next) => {
  try {
    const { email, password } = req.body;

    // Find user with password field
    const user = await User.findOne({ email }).select('+password');
    
    if (!user) {
      return sendError(res, 401, 'INVALID_CREDENTIALS', 
        'The email or password you entered is incorrect. Please try again.');
    }

    // Check if email is verified
    if (!user.isEmailVerified) {
      return sendError(res, 403, 'EMAIL_NOT_VERIFIED', 
        'Please verify your email address before logging in. Check your inbox for the verification link.', {
          email: user.email,
          canResend: true
        });
    }

    // Check if account is active
    if (!user.isActive) {
      return sendError(res, 403, 'ACCOUNT_DEACTIVATED', 
        'Your account has been deactivated. Please contact support for assistance.');
    }

    // Compare password
    const isPasswordMatch = await user.comparePassword(password);
    if (!isPasswordMatch) {
      return sendError(res, 401, 'INVALID_CREDENTIALS', 
        'The email or password you entered is incorrect. Please try again.');
    }

    // Update last login
    user.lastLogin = new Date();
    await user.save();

    // Generate tokens
    const accessToken = user.generateAccessToken();
    const refreshToken = user.generateRefreshToken();

    // Create Redis session for tracking logged-in users
    const deviceInfo = req.headers['user-agent'] || 'Unknown Device';
    const sessionId = await createSession(user._id.toString(), {
      email: user.email,
      role: user.role,
      device: deviceInfo,
      ip: req.ip || req.connection?.remoteAddress
    });
    console.log(`📍 Session created for user ${user.email}: ${sessionId}`);

    // Publish Kafka event
    await kafkaProducer.sendEvent(
      TOPICS.AUTH.USER_LOGIN,
      createEvent('auth.user.login', {
        userId: user._id.toString(),
        email: user.email,
        role: user.role,
        sessionId
      })
    );

    return sendSuccess(res, 200, 'Login successful! Welcome back.', {
      user: {
        id: user._id,
        email: user.email,
        role: user.role,
        profileId: user.profileId,
        isEmailVerified: user.isEmailVerified,
        lastLogin: user.lastLogin
      },
      accessToken,
      refreshToken,
      sessionId
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Refresh access token
 * POST /api/v1/auth/refresh-token
 */
export const refreshToken = async (req, res, next) => {
  try {
    const { refreshToken } = req.body;
    const jwt = (await import('jsonwebtoken')).default;

    // Verify refresh token
    const decoded = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET);

    if (decoded.type !== 'refresh') {
      return sendError(res, 401, 'INVALID_TOKEN_TYPE', 
        'Invalid token type. Please log in again.');
    }

    // Find user
    const user = await User.findById(decoded.id);
    if (!user) {
      return sendError(res, 401, 'USER_NOT_FOUND', 
        'User account not found. Please log in again.');
    }
    
    if (!user.isActive) {
      return sendError(res, 401, 'ACCOUNT_DEACTIVATED', 
        'Your account has been deactivated. Please contact support.');
    }

    // Generate new access token
    const newAccessToken = user.generateAccessToken();

    // Publish Kafka event
    await kafkaProducer.sendEvent(
      TOPICS.AUTH.TOKEN_REFRESHED,
      createEvent('auth.token.refreshed', {
        userId: user._id.toString()
      })
    );

    return sendSuccess(res, 200, 'Token refreshed successfully.', {
      accessToken: newAccessToken
    });
  } catch (error) {
    if (error.name === 'JsonWebTokenError') {
      return sendError(res, 401, 'INVALID_TOKEN', 
        'Your session is invalid. Please log in again.');
    }
    if (error.name === 'TokenExpiredError') {
      return sendError(res, 401, 'TOKEN_EXPIRED', 
        'Your session has expired. Please log in again.');
    }
    next(error);
  }
};

/**
 * Get current user info
 * GET /api/v1/auth/me
 */
export const getCurrentUser = async (req, res, next) => {
  try {
    // req.user is set by authentication middleware
    const user = await User.findById(req.user.id);

    if (!user) {
      return sendError(res, 404, 'USER_NOT_FOUND', 
        'User account not found.');
    }

    return sendSuccess(res, 200, 'User retrieved successfully.', { user });
  } catch (error) {
    next(error);
  }
};

/**
 * Logout user
 * POST /api/v1/auth/logout
 */
export const logout = async (req, res, next) => {
  try {
    const { sessionId } = req.body;
    
    // Delete the session from Redis
    if (sessionId) {
      await deleteSession(sessionId);
      console.log(`👋 Session deleted: ${sessionId}`);
    }
    
    await kafkaProducer.sendEvent(
      TOPICS.AUTH.USER_LOGOUT,
      createEvent('auth.user.logout', {
        userId: req.user.id,
        sessionId
      })
    );

    return sendSuccess(res, 200, 'You have been logged out successfully.');
  } catch (error) {
    next(error);
  }
};

/**
 * Verify email
 * GET /api/v1/auth/verify-email/:token
 */
export const verifyEmail = async (req, res, next) => {
  try {
    const { token } = req.params;

    // Verify token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    if (decoded.purpose !== 'email-verification') {
      return sendError(res, 400, 'INVALID_TOKEN', 
        'This verification link is invalid. Please request a new one.');
    }

    // Find user
    const user = await User.findById(decoded.id);

    if (!user) {
      return sendError(res, 404, 'USER_NOT_FOUND', 
        'User account not found. The account may have been deleted.');
    }

    if (user.isEmailVerified) {
      return sendError(res, 400, 'ALREADY_VERIFIED', 
        'Your email is already verified. You can log in now.');
    }

    // Check if token has expired
    if (user.emailVerificationExpires < new Date()) {
      return sendError(res, 400, 'TOKEN_EXPIRED', 
        'This verification link has expired. Please request a new one.');
    }

    // Verify email
    user.isEmailVerified = true;
    user.emailVerificationToken = undefined;
    user.emailVerificationExpires = undefined;
    await user.save();

    // Publish Kafka event
    await kafkaProducer.sendEvent(
      TOPICS.AUTH.USER_VERIFIED,
      createEvent('auth.user.verified', {
        userId: user._id.toString(),
        email: user.email
      })
    );

    return sendSuccess(res, 200, 'Email verified successfully! You can now log in to your account.');
  } catch (error) {
    if (error.name === 'JsonWebTokenError') {
      return sendError(res, 400, 'INVALID_TOKEN', 
        'This verification link is invalid. Please request a new one.');
    }
    if (error.name === 'TokenExpiredError') {
      return sendError(res, 400, 'TOKEN_EXPIRED', 
        'This verification link has expired. Please request a new one.');
    }
    next(error);
  }
};

/**
 * Resend verification email
 * POST /api/v1/auth/resend-verification
 */
export const resendVerification = async (req, res, next) => {
  try {
    const { email } = req.body;

    const user = await User.findOne({ email });

    if (!user) {
      return sendError(res, 404, 'USER_NOT_FOUND', 
        'No account found with this email address.');
    }

    if (user.isEmailVerified) {
      return sendError(res, 400, 'ALREADY_VERIFIED', 
        'Your email is already verified. You can log in now.');
    }

    // Generate new token
    const verificationToken = user.generateEmailVerificationToken();
    await user.save();

    // Send email
    await emailService.sendVerificationEmail(email, verificationToken);

    return sendSuccess(res, 200, 
      'Verification email sent! Please check your inbox and spam folder.');
  } catch (error) {
    next(error);
  }
};

/**
 * Forgot password - send reset email
 * POST /api/v1/auth/forgot-password
 */
export const forgotPassword = async (req, res, next) => {
  try {
    const { email } = req.body;

    const user = await User.findOne({ email });

    // Don't reveal if user exists or not (security)
    if (!user) {
      return sendSuccess(res, 200, 
        'If an account exists with this email, you will receive a password reset link shortly.');
    }

    // Generate reset token
    const resetToken = user.generatePasswordResetToken();
    await user.save();

    // Send reset email
    try {
      await emailService.sendPasswordResetEmail(email, resetToken);
    } catch (emailError) {
      user.passwordResetToken = undefined;
      user.passwordResetExpires = undefined;
      await user.save();

      return sendError(res, 500, 'EMAIL_FAILED', 
        'Unable to send password reset email. Please try again later.');
    }

    return sendSuccess(res, 200, 
      'If an account exists with this email, you will receive a password reset link shortly.');
  } catch (error) {
    next(error);
  }
};

/**
 * Reset password with token
 * POST /api/v1/auth/reset-password/:token
 */
export const resetPassword = async (req, res, next) => {
  try {
    const { token } = req.params;
    const { newPassword } = req.body;

    // Hash the token from URL
    const hashedToken = crypto
      .createHash('sha256')
      .update(token)
      .digest('hex');

    // Find user with valid token
    const user = await User.findOne({
      passwordResetToken: hashedToken,
      passwordResetExpires: { $gt: Date.now() }
    });

    if (!user) {
      return sendError(res, 400, 'INVALID_TOKEN', 
        'This password reset link is invalid or has expired. Please request a new one.');
    }

    // Set new password
    user.password = newPassword;
    user.passwordResetToken = undefined;
    user.passwordResetExpires = undefined;
    await user.save();

    // Send confirmation email
    await emailService.sendPasswordChangedEmail(user.email);

    // Publish Kafka event
    await kafkaProducer.sendEvent(
      TOPICS.AUTH.PASSWORD_RESET,
      createEvent('auth.password.reset', {
        userId: user._id.toString(),
        email: user.email
      })
    );

    return sendSuccess(res, 200, 
      'Password reset successful! You can now log in with your new password.');
  } catch (error) {
    next(error);
  }
};

/**
 * Change password (authenticated user)
 * POST /api/v1/auth/change-password
 */
export const changePassword = async (req, res, next) => {
  try {
    const { currentPassword, newPassword } = req.body;

    // Get user with password
    const user = await User.findById(req.user.id).select('+password');

    if (!user) {
      return sendError(res, 404, 'USER_NOT_FOUND', 
        'User account not found.');
    }

    // Verify current password
    const isPasswordMatch = await user.comparePassword(currentPassword);
    if (!isPasswordMatch) {
      return sendError(res, 401, 'WRONG_PASSWORD', 
        'The current password you entered is incorrect.');
    }

    // Set new password
    user.password = newPassword;
    await user.save();

    // Send confirmation email
    await emailService.sendPasswordChangedEmail(user.email);

    return sendSuccess(res, 200, 'Password changed successfully!');
  } catch (error) {
    next(error);
  }
};

/**
 * Get all active sessions for the current user
 * GET /api/v1/auth/sessions
 */
export const getActiveSessions = async (req, res, next) => {
  try {
    const sessions = await getUserSessions(req.user.id);
    
    return sendSuccess(res, 200, 'Active sessions retrieved.', {
      sessions: sessions.map(s => ({
        sessionId: s.sessionId,
        device: s.device,
        ip: s.ip,
        createdAt: s.createdAt,
        lastActivity: s.lastActivity,
        isCurrent: s.sessionId === req.body.currentSessionId
      })),
      count: sessions.length
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Logout from all devices
 * POST /api/v1/auth/logout-all
 */
export const logoutAllDevices = async (req, res, next) => {
  try {
    const count = await deleteAllUserSessions(req.user.id);
    console.log(`🚫 All sessions deleted for user ${req.user.id}: ${count} sessions`);
    
    await kafkaProducer.sendEvent(
      TOPICS.AUTH.USER_LOGOUT,
      createEvent('auth.user.logout_all', {
        userId: req.user.id,
        sessionsDeleted: count
      })
    );

    return sendSuccess(res, 200, `Successfully logged out from all ${count} device(s).`);
  } catch (error) {
    next(error);
  }
};
