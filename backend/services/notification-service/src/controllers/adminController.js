import Notification from '../models/Notification.js';
import NotificationPreference from '../models/NotificationPreference.js';
import { mongoose, getConfig } from '../../../../shared/index.js';
import { emitNotificationToUser } from '../socket/socket.js';
import { sendPushNotification } from '../services/pushNotificationService.js';

/**
 * Get notification statistics for admin dashboard
 * GET /api/v1/notifications/admin/stats
 */
export const getNotificationStats = async (req, res) => {
  try {
    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const thisWeek = new Date(today.getTime() - 7 * 24 * 60 * 60 * 1000);
    const thisMonth = new Date(now.getFullYear(), now.getMonth(), 1);

    const [
      totalNotifications,
      readNotifications,
      unreadNotifications,
      notificationsToday,
      notificationsThisWeek,
      notificationsThisMonth,
      pushSent,
      emailSent,
      smsSent
    ] = await Promise.all([
      Notification.countDocuments(),
      Notification.countDocuments({ isRead: true }),
      Notification.countDocuments({ isRead: false }),
      Notification.countDocuments({ createdAt: { $gte: today } }),
      Notification.countDocuments({ createdAt: { $gte: thisWeek } }),
      Notification.countDocuments({ createdAt: { $gte: thisMonth } }),
      Notification.countDocuments({ 'channels.push.sent': true }),
      Notification.countDocuments({ 'channels.email.sent': true }),
      Notification.countDocuments({ 'channels.sms.sent': true })
    ]);

    // Get notification type distribution
    const typeDistribution = await Notification.aggregate([
      {
        $group: {
          _id: '$type',
          count: { $sum: 1 }
        }
      },
      { $sort: { count: -1 } }
    ]);

    // Get notification trend (last 30 days)
    const thirtyDaysAgo = new Date(today.getTime() - 30 * 24 * 60 * 60 * 1000);
    
    const notificationTrend = await Notification.aggregate([
      {
        $match: {
          createdAt: { $gte: thirtyDaysAgo }
        }
      },
      {
        $group: {
          _id: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } },
          count: { $sum: 1 }
        }
      },
      { $sort: { _id: 1 } }
    ]);

    // Calculate delivery rates
    const totalSent = pushSent + emailSent + smsSent;
    const readRate = totalNotifications > 0 
      ? ((readNotifications / totalNotifications) * 100).toFixed(1)
      : '0';
    const pushDeliveryRate = totalNotifications > 0 
      ? ((pushSent / totalNotifications) * 100).toFixed(1)
      : '0';

    // Get user type distribution
    const userTypeDistribution = await Notification.aggregate([
      {
        $group: {
          _id: '$userType',
          count: { $sum: 1 }
        }
      }
    ]);

    // Get failed notifications count
    const failedPush = await Notification.countDocuments({
      'channels.push.enabled': true,
      'channels.push.sent': false,
      'channels.push.error': { $exists: true, $ne: null }
    });

    const failedEmail = await Notification.countDocuments({
      'channels.email.enabled': true,
      'channels.email.sent': false,
      'channels.email.error': { $exists: true, $ne: null }
    });

    const stats = {
      overview: {
        totalSent: totalNotifications,
        read: readNotifications,
        unread: unreadNotifications,
        readRate
      },
      channels: {
        push: {
          sent: pushSent,
          failed: failedPush,
          deliveryRate: pushDeliveryRate
        },
        email: {
          sent: emailSent,
          failed: failedEmail
        },
        sms: {
          sent: smsSent
        }
      },
      period: {
        today: notificationsToday,
        thisWeek: notificationsThisWeek,
        thisMonth: notificationsThisMonth
      },
      typeDistribution: typeDistribution.map(t => ({
        type: t._id,
        count: t.count
      })),
      userTypeDistribution: userTypeDistribution.map(u => ({
        userType: u._id,
        count: u.count
      })),
      notificationTrend,
      generatedAt: new Date().toISOString()
    };

    res.json(stats);

  } catch (error) {
    console.error('[AdminNotificationController.getNotificationStats] Error:', error);
    res.status(500).json({ message: 'Failed to fetch notification stats', error: error.message });
  }
};

/**
 * Get recent notification activity
 * GET /api/v1/notifications/admin/recent-activity
 */
export const getRecentActivity = async (req, res) => {
  try {
    const { limit = 20 } = req.query;

    const recentNotifications = await Notification.find()
      .sort({ createdAt: -1 })
      .limit(parseInt(limit))
      .select('userId userType title type channels.push.sent channels.email.sent isRead createdAt')
      .lean();

    res.json({
      recentActivity: recentNotifications,
      generatedAt: new Date().toISOString()
    });

  } catch (error) {
    console.error('[AdminNotificationController.getRecentActivity] Error:', error);
    res.status(500).json({ message: 'Failed to fetch recent activity', error: error.message });
  }
};

/**
 * Get all notifications with filters (admin oversight)
 * GET /api/v1/notifications/admin/notifications
 */
export const getAllNotifications = async (req, res) => {
  try {
    const {
      page = 1,
      limit = 20,
      type,
      userType,
      isRead,
      sortBy = 'createdAt',
      sortOrder = 'desc'
    } = req.query;

    const skip = (parseInt(page) - 1) * parseInt(limit);
    const sortOptions = { [sortBy]: sortOrder === 'asc' ? 1 : -1 };

    const query = {};
    
    if (type) {
      query.type = type;
    }
    
    if (userType) {
      query.userType = userType;
    }

    if (isRead !== undefined) {
      query.isRead = isRead === 'true';
    }

    const [notifications, total] = await Promise.all([
      Notification.find(query)
        .sort(sortOptions)
        .skip(skip)
        .limit(parseInt(limit))
        .lean(),
      Notification.countDocuments(query)
    ]);

    res.json({
      notifications,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit))
      }
    });

  } catch (error) {
    console.error('[AdminNotificationController.getAllNotifications] Error:', error);
    res.status(500).json({ message: 'Failed to fetch notifications', error: error.message });
  }
};

/**
 * Get notification preferences summary
 * GET /api/v1/notifications/admin/preferences-summary
 */
export const getPreferencesSummary = async (req, res) => {
  try {
    const [
      totalPreferences,
      pushEnabled,
      emailEnabled,
      smsEnabled
    ] = await Promise.all([
      NotificationPreference.countDocuments(),
      NotificationPreference.countDocuments({ 'push.enabled': true }),
      NotificationPreference.countDocuments({ 'email.enabled': true }),
      NotificationPreference.countDocuments({ 'sms.enabled': true })
    ]);

    res.json({
      totalUsers: totalPreferences,
      channelPreferences: {
        push: {
          enabled: pushEnabled,
          percentage: totalPreferences > 0 
            ? ((pushEnabled / totalPreferences) * 100).toFixed(1)
            : '0'
        },
        email: {
          enabled: emailEnabled,
          percentage: totalPreferences > 0 
            ? ((emailEnabled / totalPreferences) * 100).toFixed(1)
            : '0'
        },
        sms: {
          enabled: smsEnabled,
          percentage: totalPreferences > 0 
            ? ((smsEnabled / totalPreferences) * 100).toFixed(1)
            : '0'
        }
      },
      generatedAt: new Date().toISOString()
    });

  } catch (error) {
    console.error('[AdminNotificationController.getPreferencesSummary] Error:', error);
    res.status(500).json({ message: 'Failed to fetch preferences summary', error: error.message });
  }
};

/**
 * Send admin alert notification (service-to-service)
 * Called by audit-service for critical events
 * POST /api/v1/notifications/admin-alert
 */
export const sendAdminAlert = async (req, res) => {
  try {
    const { title, body, severity = 'high', metadata = {} } = req.body;

    if (!title || !body) {
      return res.status(400).json({ 
        success: false,
        message: 'Title and body are required' 
      });
    }

    // Get all admin users from auth database
    let adminUsers = [];
    
    try {
      // Create a connection to the auth database to fetch admin users
      const authDbName = getConfig('AUTH_DB_NAME') || 'esante_auth';
      const authDb = mongoose.connection.client.db(authDbName);
      const usersCollection = authDb.collection('users');
      const admins = await usersCollection.find({ role: 'admin', isActive: true }).toArray();
      adminUsers = admins.map(admin => ({
        _id: admin._id,
        email: admin.email
      }));
      console.log(`[AdminAlert] Found ${adminUsers.length} admin users in ${authDbName}`);
    } catch (dbError) {
      console.error('[AdminAlert] Failed to fetch admins from auth DB:', dbError.message);
      // Fallback: try to find from notification preferences with admin type
      const adminPrefs = await NotificationPreference.find({ userType: 'admin' });
      adminUsers = adminPrefs.map(pref => ({ _id: pref.userId }));
    }

    if (adminUsers.length === 0) {
      console.log('[AdminAlert] No admin users found to notify');
      return res.json({
        success: true,
        message: 'No admin users to notify',
        notificationsSent: 0
      });
    }

    // Create notifications for all admins
    const notifications = [];
    const priorityMap = {
      low: 'low',
      medium: 'medium',
      high: 'high',
      critical: 'urgent'
    };

    for (const admin of adminUsers) {
      const notification = await Notification.create({
        userId: admin._id,
        userType: 'admin',
        title,
        body,
        type: 'admin_alert',
        priority: priorityMap[severity] || 'high',
        relatedResource: metadata.auditLogId ? {
          resourceType: 'audit',
          resourceId: new mongoose.Types.ObjectId(metadata.auditLogId)
        } : undefined,
        actionData: metadata,
        channels: {
          push: { enabled: true },
          email: { enabled: severity === 'critical' },
          inApp: { enabled: true, delivered: true }
        }
      });

      notifications.push(notification);

      // Emit real-time notification via socket
      try {
        emitNotificationToUser(admin._id.toString(), {
          id: notification._id.toString(),
          title,
          body,
          type: 'admin_alert',
          priority: notification.priority,
          createdAt: notification.createdAt,
          metadata
        });
      } catch (socketError) {
        console.error(`[AdminAlert] Socket emit failed for admin ${admin._id}:`, socketError.message);
      }

      // Send push notification for high/critical severity
      if (severity === 'high' || severity === 'critical') {
        try {
          await sendPushNotification(admin._id.toString(), {
            title: `🚨 ${title}`,
            body,
            data: {
              type: 'admin_alert',
              notificationId: notification._id.toString(),
              severity
            }
          });
          notification.channels.push.sent = true;
          notification.channels.push.sentAt = new Date();
          await notification.save();
        } catch (pushError) {
          console.error(`[AdminAlert] Push notification failed for admin ${admin._id}:`, pushError.message);
        }
      }
    }

    console.log(`✅ [AdminAlert] Sent ${notifications.length} admin alerts: ${title}`);

    res.json({
      success: true,
      message: 'Admin alerts sent successfully',
      notificationsSent: notifications.length,
      notificationIds: notifications.map(n => n._id)
    });

  } catch (error) {
    console.error('[AdminNotificationController.sendAdminAlert] Error:', error);
    res.status(500).json({ 
      success: false,
      message: 'Failed to send admin alerts', 
      error: error.message 
    });
  }
};
