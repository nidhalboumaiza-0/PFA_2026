import express from 'express';
import {
  getUserNotifications,
  getUserUnreadCount,
  markAsRead,
  markAllAsReadHandler,
  getPreferences,
  updateUserPreferences,
  registerDeviceHandler,
  unregisterDeviceHandler,
} from '../controllers/notificationController.js';
import { auth } from '../../../../shared/index.js';
import {
  validate,
  getNotificationsSchema,
  updatePreferencesSchema,
  registerDeviceSchema,
} from '../validators/notificationValidator.js';

const router = express.Router();

// All routes require authentication
router.use(auth);

// Get notifications for current user
router.get('/', validate(getNotificationsSchema), getUserNotifications);

// Get unread notification count
router.get('/unread-count', getUserUnreadCount);

// Mark notification as read
router.put('/:id/read', markAsRead);

// Mark all notifications as read
router.put('/mark-all-read', markAllAsReadHandler);

// Get notification preferences
router.get('/preferences', getPreferences);

// Update notification preferences
router.put('/preferences', validate(updatePreferencesSchema), updateUserPreferences);

// Register device for push notifications
router.post('/register-device', validate(registerDeviceSchema), registerDeviceHandler);

// Unregister device
router.delete('/devices/:playerId', unregisterDeviceHandler);

export default router;
