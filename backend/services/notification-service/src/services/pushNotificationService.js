import * as OneSignal from '@onesignal/node-onesignal';
import { getConfig } from '../../../../shared/index.js';
import NotificationPreference from '../models/NotificationPreference.js';

// OneSignal client singleton
let oneSignalClient = null;

/**
 * Get or create OneSignal client
 */
const getOneSignalClient = () => {
  if (!oneSignalClient) {
    const apiKey = getConfig('ONESIGNAL_REST_API_KEY');
    
    const configuration = OneSignal.createConfiguration({
      restApiKey: apiKey,
    });
    
    oneSignalClient = new OneSignal.DefaultApi(configuration);
  }
  return oneSignalClient;
};

/**
 * Send push notification to user's devices via OneSignal SDK
 * @param {string} userId - User ID
 * @param {object} notification - Notification data (title, body, data, priority)
 * @returns {Promise<object>} - { sent: boolean, oneSignalId?: string, sentAt?: Date, error?: string }
 */
export const sendPushNotification = async (userId, notification) => {
  try {
    console.log(`📱 Attempting to send push notification to user: ${userId}`);
    
    // Get user's notification preferences
    const preferences = await NotificationPreference.findOne({ userId });

    if (!preferences || preferences.devices.length === 0) {
      console.log(`⚠️ No devices registered for user ${userId}`);
      return {
        sent: false,
        error: 'No devices registered for user',
      };
    }

    console.log(`📱 Found ${preferences.devices.length} device(s) for user ${userId}`);

    // Get all OneSignal player IDs (subscription IDs)
    const subscriptionIds = preferences.getPlayerIds();
    console.log(`📱 Subscription IDs: ${subscriptionIds.join(', ')}`);

    // Get OneSignal credentials from config
    const appId = getConfig('ONESIGNAL_APP_ID');
    const apiKey = getConfig('ONESIGNAL_REST_API_KEY');

    if (!appId || !apiKey) {
      console.error('❌ OneSignal credentials not configured. ONESIGNAL_APP_ID:', appId ? 'set' : 'missing', 'ONESIGNAL_REST_API_KEY:', apiKey ? 'set' : 'missing');
      return {
        sent: false,
        error: 'OneSignal credentials not configured',
      };
    }

    console.log(`📱 Using OneSignal App ID: ${appId}`);

    // Create OneSignal notification using SDK
    const oneSignalNotification = new OneSignal.Notification();
    oneSignalNotification.app_id = appId;
    oneSignalNotification.contents = { en: notification.body };
    oneSignalNotification.headings = { en: notification.title };
    oneSignalNotification.include_subscription_ids = subscriptionIds;
    oneSignalNotification.data = notification.actionData || {};
    
    // Set priority
    const priorityMap = {
      low: 3,
      medium: 5,
      high: 8,
      urgent: 10,
    };
    oneSignalNotification.priority = priorityMap[notification.priority] || 5;
    
    // Set sound for urgent notifications
    if (notification.priority === 'urgent') {
      oneSignalNotification.ios_sound = 'alarm.wav';
      oneSignalNotification.android_channel_id = 'urgent';
    }

    // Add action URL if provided
    if (notification.actionUrl) {
      oneSignalNotification.url = notification.actionUrl;
    }

    console.log(`📱 Sending OneSignal notification via SDK...`);

    // Send notification via OneSignal SDK
    const client = getOneSignalClient();
    const response = await client.createNotification(oneSignalNotification);
    
    console.log(`📱 OneSignal response:`, JSON.stringify(response, null, 2));
    console.log(`✅ Push notification sent successfully, ID: ${response.id}`);

    return {
      sent: true,
      oneSignalId: response.id,
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
