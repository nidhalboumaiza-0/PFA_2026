import cron from 'node-cron';
import Notification from '../models/Notification.js';
import { sendPushNotification } from '../services/pushNotificationService.js';

/**
 * Process scheduled notifications that are due
 */
const processScheduledNotifications = async () => {
  try {
    const now = new Date();

    // Find notifications that are scheduled and due to be sent
    const dueNotifications = await Notification.find({
      scheduledFor: { $lte: now },
      'channels.push.sent': false,
      'channels.push.enabled': true,
    });

    if (dueNotifications.length === 0) {
      return;
    }

    console.log(`📅 Processing ${dueNotifications.length} scheduled notification(s)...`);

    for (const notification of dueNotifications) {
      try {
        // Send push notification
        const pushResult = await sendPushNotification(notification.userId, {
          title: notification.title,
          body: notification.body,
          priority: notification.priority,
          actionUrl: notification.actionUrl,
          actionData: notification.actionData,
        });

        // Update notification status
        notification.channels.push.sent = pushResult.sent;
        notification.channels.push.sentAt = pushResult.sentAt;
        notification.channels.push.oneSignalId = pushResult.oneSignalId;
        notification.channels.push.error = pushResult.error;

        await notification.save();

        console.log(
          `✅ Scheduled notification ${notification._id} sent to user ${notification.userId}`
        );
      } catch (error) {
        console.error(`Error sending scheduled notification ${notification._id}:`, error);
      }
    }

    console.log(`✅ Processed ${dueNotifications.length} scheduled notification(s)`);
  } catch (error) {
    console.error('Error processing scheduled notifications:', error);
  }
};

/**
 * Start scheduled notification job
 */
export const startScheduledNotificationJob = () => {
  const interval = process.env.SCHEDULED_NOTIFICATION_INTERVAL || '* * * * *'; // Every minute by default

  cron.schedule(interval, async () => {
    await processScheduledNotifications();
  });

  console.log(`✅ Scheduled notification job started (interval: ${interval})`);
};
