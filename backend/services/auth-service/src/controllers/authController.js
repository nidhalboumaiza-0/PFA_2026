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
 * Register new user
 * POST /api/v1/auth/register
 */
export const register = async (req, res, next) => {
  try {
    const { email, password, role, profileData } = req.body;

    // Check if user already exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(409).json({
        message: 'Email already registered'
      });
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

    res.status(201).json({
      message: 'Registration successful. Please check your email for verification link.',
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
      return res.status(401).json({
        message: 'Invalid email or password'
      });
    }

    // Check if email is verified
    if (!user.isEmailVerified) {
      return res.status(403).json({
        message: 'Please verify your email before logging in'
      });
    }

    // Check if account is active
    if (!user.isActive) {
      return res.status(403).json({
        message: 'Your account has been deactivated. Please contact support.'
      });
    }

    // Compare password
    const isPasswordMatch = await user.comparePassword(password);
    if (!isPasswordMatch) {
      return res.status(401).json({
        message: 'Invalid email or password'
      });
    }

    // Update last login
    user.lastLogin = new Date();
    await user.save();

    // Generate tokens
    const accessToken = user.generateAccessToken();
    const refreshToken = user.generateRefreshToken();

    // Create Redis session for tracking logged-in users
    // This allows us to invalidate sessions on logout and track all active sessions
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

    res.status(200).json({
      message: 'Login successful',
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
      sessionId  // Client should store this for logout
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
      return res.status(401).json({
        message: 'Invalid token type'
      });
    }

    // Find user
    const user = await User.findById(decoded.id);
    if (!user || !user.isActive) {
      return res.status(401).json({
        message: 'User not found or inactive'
      });
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

    res.status(200).json({
      message: 'Token refreshed successfully',
      accessToken: newAccessToken
    });
  } catch (error) {
    if (error.name === 'JsonWebTokenError' || error.name === 'TokenExpiredError') {
      return res.status(401).json({
        message: 'Invalid or expired refresh token'
      });
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
      return res.status(404).json({
        message: 'User not found'
      });
    }

    res.status(200).json({
      user
    });
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

    res.status(200).json({
      message: 'Logout successful'
    });
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
      return res.status(400).json({
        message: 'Invalid verification token'
      });
    }

    // Find user
    const user = await User.findById(decoded.id);

    if (!user) {
      return res.status(404).json({
        message: 'User not found'
      });
    }

    if (user.isEmailVerified) {
      return res.status(400).json({
        message: 'Email already verified'
      });
    }

    // Check if token has expired
    if (user.emailVerificationExpires < new Date()) {
      return res.status(400).json({
        message: 'Verification token has expired. Please request a new one.'
      });
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

    res.status(200).json({
      message: 'Email verified successfully. You can now log in.'
    });
  } catch (error) {
    if (error.name === 'JsonWebTokenError' || error.name === 'TokenExpiredError') {
      return res.status(400).json({
        message: 'Invalid or expired verification token'
      });
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
      return res.status(404).json({
        message: 'User not found'
      });
    }

    if (user.isEmailVerified) {
      return res.status(400).json({
        message: 'Email already verified'
      });
    }

    // Generate new token
    const verificationToken = user.generateEmailVerificationToken();
    await user.save();

    // Send email
    await emailService.sendVerificationEmail(email, verificationToken);

    res.status(200).json({
      message: 'Verification email sent successfully'
    });
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
      return res.status(200).json({
        message: 'If that email exists, a password reset link has been sent.'
      });
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

      return res.status(500).json({
        message: 'Error sending password reset email. Please try again.'
      });
    }

    res.status(200).json({
      message: 'If that email exists, a password reset link has been sent.'
    });
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
      return res.status(400).json({
        message: 'Invalid or expired password reset token'
      });
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

    res.status(200).json({
      message: 'Password reset successful. You can now log in with your new password.'
    });
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
      return res.status(404).json({
        message: 'User not found'
      });
    }

    // Verify current password
    const isPasswordMatch = await user.comparePassword(currentPassword);
    if (!isPasswordMatch) {
      return res.status(401).json({
        message: 'Current password is incorrect'
      });
    }

    // Set new password
    user.password = newPassword;
    await user.save();

    // Send confirmation email
    await emailService.sendPasswordChangedEmail(user.email);

    res.status(200).json({
      message: 'Password changed successfully'
    });
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
    
    res.status(200).json({
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

    res.status(200).json({
      message: `Logged out from all ${count} devices`
    });
  } catch (error) {
    next(error);
  }
};
