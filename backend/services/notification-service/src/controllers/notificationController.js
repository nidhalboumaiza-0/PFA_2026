import {
  getNotifications,
  markNotificationAsRead,
  markAllNotificationsAsRead,
  getUnreadCount,
  getNotificationPreferences,
  updatePreferences,
  registerDevice,
  unregisterDevice,
} from '../services/notificationService.js';
import { formatNotificationForResponse, calculatePagination } from '../utils/helpers.js';

/**
 * Get notifications for current user
 * GET /api/v1/notifications
 */
export const getUserNotifications = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { isRead, type, page, limit } = req.query;

    const result = await getNotifications(userId, { isRead, type, page, limit });

    const formattedNotifications = result.notifications.map(formatNotificationForResponse);
    const pagination = calculatePagination(result.page, result.limit, result.totalCount);

    res.json({
      success: true,
      data: {
        notifications: formattedNotifications,
        unreadCount: result.unreadCount,
        pagination,
      },
    });
  } catch (error) {
    console.error('Error getting notifications:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching notifications',
      error: error.message,
    });
  }
};

/**
 * Get unread notification count
 * GET /api/v1/notifications/unread-count
 */
export const getUserUnreadCount = async (req, res) => {
  try {
    const userId = req.user.userId;
    const count = await getUnreadCount(userId);

    res.json({
      success: true,
      data: { unreadCount: count },
    });
  } catch (error) {
    console.error('Error getting unread count:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching unread count',
      error: error.message,
    });
  }
};

/**
 * Mark notification as read
 * PUT /api/v1/notifications/:id/read
 */
export const markAsRead = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.userId;

    const notification = await markNotificationAsRead(id, userId);

    res.json({
      success: true,
      message: 'Notification marked as read',
      data: formatNotificationForResponse(notification),
    });
  } catch (error) {
    console.error('Error marking notification as read:', error);
    
    if (error.message === 'Notification not found') {
      return res.status(404).json({
        success: false,
        message: 'Notification not found',
      });
    }

    res.status(500).json({
      success: false,
      message: 'Error marking notification as read',
      error: error.message,
    });
  }
};

/**
 * Mark all notifications as read
 * PUT /api/v1/notifications/mark-all-read
 */
export const markAllAsReadHandler = async (req, res) => {
  try {
    const userId = req.user.userId;
    const count = await markAllNotificationsAsRead(userId);

    res.json({
      success: true,
      message: `${count} notification(s) marked as read`,
      data: { count },
    });
  } catch (error) {
    console.error('Error marking all notifications as read:', error);
    res.status(500).json({
      success: false,
      message: 'Error marking notifications as read',
      error: error.message,
    });
  }
};

/**
 * Get notification preferences
 * GET /api/v1/notifications/preferences
 */
export const getPreferences = async (req, res) => {
  try {
    const userId = req.user.userId;
    const preferences = await getNotificationPreferences(userId);

    res.json({
      success: true,
      data: preferences,
    });
  } catch (error) {
    console.error('Error getting preferences:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching notification preferences',
      error: error.message,
    });
  }
};

/**
 * Update notification preferences
 * PUT /api/v1/notifications/preferences
 */
export const updateUserPreferences = async (req, res) => {
  try {
    const userId = req.user.userId;
    const preferencesData = req.body;

    const preferences = await updatePreferences(userId, preferencesData);

    res.json({
      success: true,
      message: 'Notification preferences updated successfully',
      data: preferences,
    });
  } catch (error) {
    console.error('Error updating preferences:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating notification preferences',
      error: error.message,
    });
  }
};

/**
 * Register device for push notifications
 * POST /api/v1/notifications/register-device
 */
export const registerDeviceHandler = async (req, res) => {
  try {
    const userId = req.user.userId;
    const deviceData = req.body;

    const result = await registerDevice(userId, deviceData);

    res.json({
      success: true,
      message: result.message,
      data: { added: result.added },
    });
  } catch (error) {
    console.error('Error registering device:', error);
    res.status(500).json({
      success: false,
      message: 'Error registering device',
      error: error.message,
    });
  }
};

/**
 * Unregister device
 * DELETE /api/v1/notifications/devices/:playerId
 */
export const unregisterDeviceHandler = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { playerId } = req.params;

    const removed = await unregisterDevice(userId, playerId);

    if (!removed) {
      return res.status(404).json({
        success: false,
        message: 'Device not found',
      });
    }

    res.json({
      success: true,
      message: 'Device unregistered successfully',
    });
  } catch (error) {
    console.error('Error unregistering device:', error);
    res.status(500).json({
      success: false,
      message: 'Error unregistering device',
      error: error.message,
    });
  }
};
