import Notification from '../models/Notification.js';
import NotificationPreference from '../models/NotificationPreference.js';
import { sendPushNotification } from './pushNotificationService.js';
import { sendEmailNotification, isQuietHours } from './emailService.js';
import { emitNotificationToUser, isUserConnectedLocally } from '../socket/socket.js';

// Socket.IO instance (will be set by server)
let io = null;

export const setSocketIO = (socketIO) => {
  io = socketIO;
};

export const getSocketIO = () => {
  return io;
};

/**
 * Get notification type to preference key mapping
 * @param {string} type - Notification type
 * @returns {string} - Preference key
 */
const getPreferenceKey = (type) => {
  const typeMap = {
    new_appointment_request: 'appointmentConfirmed', // Uses same preference as appointments
    appointment_confirmed: 'appointmentConfirmed',
    appointment_rejected: 'appointmentConfirmed',
    appointment_reminder: 'appointmentReminder',
    appointment_cancelled: 'appointmentCancelled',
    appointment_rescheduled: 'appointmentConfirmed',
    reschedule_approved: 'appointmentConfirmed',
    reschedule_rejected: 'appointmentConfirmed',
    reschedule_requested: 'appointmentConfirmed',
    new_message: 'newMessage',
    referral_received: 'referral',
    referral_scheduled: 'referral',
    consultation_created: 'prescription',
    prescription_created: 'prescription',
    document_uploaded: 'prescription',
    system_alert: 'systemAlert',
  };

  return typeMap[type] || 'systemAlert';
};

/**
 * Get or create notification preferences for user
 * @param {string} userId - User ID
 * @returns {Promise<object>} - Notification preferences
 */
export const getNotificationPreferences = async (userId) => {
  return await NotificationPreference.getOrCreate(userId);
};

/**
 * Get channel preferences for specific notification type
 * @param {object} preferences - User's notification preferences
 * @param {string} type - Notification type
 * @returns {object} - Channel preferences { push, email, inApp }
 */
const getPreferencesForType = (preferences, type) => {
  const preferenceKey = getPreferenceKey(type);
  return preferences.preferences[preferenceKey] || { push: true, email: true, inApp: true };
};

/**
 * Create and send notification
 * @param {object} notificationData - Notification data
 * @returns {Promise<object>} - Created notification
 */
export const createNotification = async (notificationData) => {
  try {
    const {
      userId,
      userType,
      title,
      body,
      type,
      relatedResource,
      priority = 'medium',
      actionUrl,
      actionData,
      scheduledFor,
    } = notificationData;

    // Get user's notification preferences
    const preferences = await getNotificationPreferences(userId);
    const channelPrefs = getPreferencesForType(preferences, type);

    // Check quiet hours for push notifications
    const inQuietHours = isQuietHours(preferences);

    // Create notification in database
    const notification = new Notification({
      userId,
      userType,
      title,
      body,
      type,
      relatedResource,
      priority,
      actionUrl,
      actionData,
      scheduledFor,
      channels: {
        push: {
          enabled: channelPrefs.push && !inQuietHours, // Disable push during quiet hours
          sent: false,
        },
        email: {
          enabled: channelPrefs.email, // Email ignores quiet hours
          sent: false,
        },
        inApp: {
          enabled: channelPrefs.inApp,
          delivered: false,
        },
      },
    });

    // If scheduled, save and return (will be sent by background job)
    if (scheduledFor && new Date(scheduledFor) > new Date()) {
      await notification.save();
      return notification;
    }

    // Send push notification if enabled (respects quiet hours)
    if (channelPrefs.push && !inQuietHours) {
      const pushResult = await sendPushNotification(userId, {
        title,
        body,
        priority,
        actionUrl,
        actionData,
      });

      notification.channels.push.sent = pushResult.sent;
      notification.channels.push.sentAt = pushResult.sentAt;
      notification.channels.push.oneSignalId = pushResult.oneSignalId;
      notification.channels.push.error = pushResult.error;
    }

    // Send email notification if enabled (ignores quiet hours)
    if (channelPrefs.email) {
      const emailResult = await sendEmailNotification(userId, notification);

      notification.channels.email.sent = emailResult.sent;
      notification.channels.email.sentAt = emailResult.sentAt;
      notification.channels.email.messageId = emailResult.messageId;
      notification.channels.email.error = emailResult.error;
    }

    // Send in-app notification via Socket.IO if enabled
    // Always emit - Socket.IO will deliver if user is connected, otherwise it's a no-op
    // Push notifications (OneSignal) handle offline delivery separately
    if (channelPrefs.inApp) {
      // Check if user is connected to THIS service's Socket.IO (local check, no HTTP call)
      const isConnected = isUserConnectedLocally(userId);
      
      // Always emit the notification - if user is connected they get it immediately
      // If not connected, they'll see it when they fetch notifications + get push via OneSignal
      emitNotificationToUser(userId, {
        id: notification._id,
        title,
        body,
        type,
        priority,
        actionUrl,
        actionData,
        createdAt: new Date(),
      });
      
      // Track if it was delivered in real-time (user was connected)
      notification.channels.inApp.delivered = isConnected;
      
      if (isConnected) {
        console.log(`📡 Real-time notification delivered to user ${userId} via Socket.IO`);
      } else {
        console.log(`📡 Socket.IO event emitted for user ${userId} (user not currently connected - will receive via push/fetch)`);
      }
    }

    // Save notification with delivery status
    await notification.save();

    return notification;
  } catch (error) {
    console.error('Error creating notification:', error);
    throw error;
  }
};

/**
 * Get notifications for user with filters
 * @param {string} userId - User ID
 * @param {object} filters - { isRead, type, page, limit }
 * @returns {Promise<object>} - Notifications and pagination
 */
export const getNotifications = async (userId, filters = {}) => {
  const { isRead, type, page = 1, limit = 20 } = filters;

  const query = { userId };

  if (isRead !== undefined) {
    query.isRead = isRead;
  }

  if (type) {
    query.type = type;
  }

  const skip = (page - 1) * limit;

  const [notifications, totalCount, unreadCount] = await Promise.all([
    Notification.find(query).sort({ createdAt: -1 }).skip(skip).limit(limit),
    Notification.countDocuments(query),
    Notification.getUnreadCountForUser(userId),
  ]);

  return {
    notifications,
    totalCount,
    unreadCount,
    page,
    limit,
  };
};

/**
 * Mark notification as read
 * @param {string} notificationId - Notification ID
 * @param {string} userId - User ID
 * @returns {Promise<object>} - Updated notification
 */
export const markNotificationAsRead = async (notificationId, userId) => {
  const notification = await Notification.findOne({
    _id: notificationId,
    userId,
  });

  if (!notification) {
    throw new Error('Notification not found');
  }

  await notification.markAsRead();
  await notification.save();

  return notification;
};

/**
 * Mark all notifications as read for user
 * @param {string} userId - User ID
 * @returns {Promise<number>} - Number of notifications marked as read
 */
export const markAllNotificationsAsRead = async (userId) => {
  const result = await Notification.markAllAsReadForUser(userId);
  return result.modifiedCount;
};

/**
 * Get unread notification count for user
 * @param {string} userId - User ID
 * @returns {Promise<number>} - Unread count
 */
export const getUnreadCount = async (userId) => {
  return await Notification.getUnreadCountForUser(userId);
};

/**
 * Update notification preferences
 * @param {string} userId - User ID
 * @param {object} preferencesData - New preferences
 * @returns {Promise<object>} - Updated preferences
 */
export const updatePreferences = async (userId, preferencesData) => {
  let preferences = await NotificationPreference.findOne({ userId });

  if (!preferences) {
    preferences = new NotificationPreference({ userId });
  }

  preferences.preferences = {
    ...preferences.preferences,
    ...preferencesData.preferences,
  };

  // Update quiet hours if provided
  if (preferencesData.quietHours) {
    preferences.quietHours = {
      ...preferences.quietHours,
      ...preferencesData.quietHours,
    };
  }

  await preferences.save();
  return preferences;
};

/**
 * Register device for push notifications
 * @param {string} userId - User ID
 * @param {object} deviceData - Device data
 * @returns {Promise<object>} - Result
 */
export const registerDevice = async (userId, deviceData) => {
  const preferences = await getNotificationPreferences(userId);
  const result = preferences.addDevice(deviceData);
  await preferences.save();
  return result;
};

/**
 * Unregister device
 * @param {string} userId - User ID
 * @param {string} playerId - OneSignal player ID
 * @returns {Promise<boolean>} - Success
 */
export const unregisterDevice = async (userId, playerId) => {
  const preferences = await NotificationPreference.findOne({ userId });

  if (!preferences) {
    return false;
  }

  const removed = preferences.removeDevice(playerId);

  if (removed) {
    await preferences.save();
  }

  return removed;
};
