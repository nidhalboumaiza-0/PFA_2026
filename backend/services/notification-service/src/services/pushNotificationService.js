import oneSignalClient from '../config/onesignal.js';
import NotificationPreference from '../models/NotificationPreference.js';

/**
 * Send push notification to user's devices via OneSignal
 * @param {string} userId - User ID
 * @param {object} notification - Notification data (title, body, data, priority)
 * @returns {Promise<object>} - { sent: boolean, oneSignalId?: string, sentAt?: Date, error?: string }
 */
export const sendPushNotification = async (userId, notification) => {
  try {
    // Get user's notification preferences
    const preferences = await NotificationPreference.findOne({ userId });

    if (!preferences || preferences.devices.length === 0) {
      return {
        sent: false,
        error: 'No devices registered for user',
      };
    }

    // Get all OneSignal player IDs
    const playerIds = preferences.getPlayerIds();

    // Map priority to OneSignal priority (0-10)
    const priorityMap = {
      low: 3,
      medium: 5,
      high: 8,
      urgent: 10,
    };

    // Create OneSignal notification
    const oneSignalNotification = {
      include_player_ids: playerIds,
      headings: {
        en: notification.title,
      },
      contents: {
        en: notification.body,
      },
      data: notification.actionData || {},
      priority: priorityMap[notification.priority] || 5,
      android_channel_id: notification.priority === 'urgent' ? 'urgent' : 'default',
      sound: notification.priority === 'urgent' ? 'alarm' : 'default',
    };

    // Add action URL if provided
    if (notification.actionUrl) {
      oneSignalNotification.url = notification.actionUrl;
    }

    // Send notification via OneSignal
    const response = await oneSignalClient.createNotification(oneSignalNotification);

    return {
      sent: true,
      oneSignalId: response.body.id,
      sentAt: new Date(),
    };
  } catch (error) {
    console.error('Error sending push notification:', error);
    return {
      sent: false,
      error: error.message || 'Failed to send push notification',
    };
  }
};
