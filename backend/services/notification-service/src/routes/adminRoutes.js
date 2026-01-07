import express from 'express';
import { auth, adminAuth } from '../../../../shared/index.js';
import {
  getNotificationStats,
  getRecentActivity,
  getAllNotifications,
  getPreferencesSummary
} from '../controllers/adminController.js';

const router = express.Router();

// All admin routes require authentication and admin role
router.use(auth, adminAuth);

// Get notification statistics
router.get('/stats', getNotificationStats);

// Get recent notification activity
router.get('/recent-activity', getRecentActivity);

// Get all notifications (admin oversight)
router.get('/notifications', getAllNotifications);

// Get notification preferences summary
router.get('/preferences-summary', getPreferencesSummary);

export default router;
