import express from 'express';
import * as authController from '../controllers/authController.js';
import {
  validateRegister,
  validateLogin,
  validateRefreshToken,
  validateForgotPassword,
  validateResetPassword,
  validateChangePassword,
  validateResendVerification
} from '../validators/authValidator.js';
import { auth } from '../../../../shared/index.js';

const router = express.Router();

// Public routes
router.post('/register', validateRegister, authController.register);
router.get('/verify-email/:token', authController.verifyEmail);
router.post('/resend-verification', validateResendVerification, authController.resendVerification);
router.post('/login', validateLogin, authController.login);
router.post('/refresh-token', validateRefreshToken, authController.refreshToken);
router.post('/forgot-password', validateForgotPassword, authController.forgotPassword);
router.post('/reset-password/:token', validateResetPassword, authController.resetPassword);

// Protected routes
router.get('/me', auth, authController.getCurrentUser);
router.post('/change-password', auth, validateChangePassword, authController.changePassword);
router.post('/logout', auth, authController.logout);
router.get('/sessions', auth, authController.getActiveSessions);
router.post('/logout-all', auth, authController.logoutAllDevices);

export default router;
