const catchAsync = require("../utils/catchAsync");
const AppError = require("../utils/appError");
const Notification = require("../models/notificationModel");
const User = require("../models/userModel");
const mongoose = require("mongoose");
const oneSignalService = require("../utils/oneSignalService");

// Get all notifications for the current user
exports.getNotifications = catchAsync(async (req, res, next) => {
  const userId = req.user.id;
  const { page = 1, limit = 20 } = req.query;
  const skip = (page - 1) * limit;

  const notifications = await Notification.find({
    recipientId: userId,
  })
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(parseInt(limit))
    .populate({
      path: "senderId",
      select: "name lastName",
    });

  const totalCount = await Notification.countDocuments({
    recipientId: userId,
  });

  res.status(200).json({
    status: "success",
    results: notifications.length,
    totalCount,
    data: {
      notifications,
    },
  });
});

// Mark a notification as read
exports.markNotificationAsRead = catchAsync(
  async (req, res, next) => {
    const notificationId = req.params.id;
    const userId = req.user.id;

    const notification = await Notification.findById(notificationId);

    if (!notification) {
      return next(new AppError("Notification non trouvée", 404));
    }

    // Check if the user is the recipient
    if (notification.recipientId.toString() !== userId) {
      return next(
        new AppError(
          "Vous n'êtes pas autorisé à modifier cette notification",
          403
        )
      );
    }

    notification.isRead = true;
    await notification.save();

    res.status(200).json({
      status: "success",
      data: {
        notification,
      },
    });
  }
);

// Mark all notifications as read
exports.markAllNotificationsAsRead = catchAsync(
  async (req, res, next) => {
    const userId = req.user.id;

    await Notification.updateMany(
      { recipientId: userId, isRead: false },
      { isRead: true }
    );

    res.status(200).json({
      status: "success",
      message: "Toutes les notifications ont été marquées comme lues",
    });
  }
);

// Delete a notification
exports.deleteNotification = catchAsync(async (req, res, next) => {
  const notificationId = req.params.id;
  const userId = req.user.id;

  const notification = await Notification.findById(notificationId);

  if (!notification) {
    return next(new AppError("Notification non trouvée", 404));
  }

  // Check if the user is the recipient
  if (notification.recipientId.toString() !== userId) {
    return next(
      new AppError(
        "Vous n'êtes pas autorisé à supprimer cette notification",
        403
      )
    );
  }

  await notification.deleteOne();

  res.status(204).json({
    status: "success",
    data: null,
  });
});

// Get unread notifications count
exports.getUnreadNotificationsCount = catchAsync(
  async (req, res, next) => {
    const userId = req.user.id;

    const count = await Notification.countDocuments({
      recipientId: userId,
      isRead: false,
    });

    res.status(200).json({
      status: "success",
      data: {
        count,
      },
    });
  }
);

// Create a notification (internal function)
exports.createNotification = async (
  title,
  body,
  senderId,
  recipientId,
  type,
  appointmentId = null,
  prescriptionId = null,
  data = {}
) => {
  try {
    // Create notification in MongoDB
    const notification = await Notification.create({
      title,
      body,
      senderId,
      recipientId,
      type: type || "general",
      appointmentId,
      prescriptionId,
      data,
      isRead: false,
    });

    // Send push notification via OneSignal if recipient has a player ID
    try {
      const recipient = await User.findById(recipientId);
      if (recipient && recipient.oneSignalPlayerId) {
        await oneSignalService.sendNotificationToUsers(
          [recipient.oneSignalPlayerId],
          title,
          body,
          {
            notificationId: notification._id.toString(),
            type,
            appointmentId: appointmentId
              ? appointmentId.toString()
              : null,
            prescriptionId: prescriptionId
              ? prescriptionId.toString()
              : null,
            ...data,
          }
        );
      }
    } catch (error) {
      console.error("Error sending push notification:", error);
      // Continue even if push notification fails
    }

    return notification;
  } catch (error) {
    console.error("Error creating notification:", error);
    throw error;
  }
};

// Send push notification to multiple users
exports.sendPushNotification = catchAsync(async (req, res, next) => {
  const { title, body, userIds, data = {} } = req.body;

  if (!title || !body || !userIds || !Array.isArray(userIds)) {
    return next(
      new AppError("Title, body, and userIds array are required", 400)
    );
  }

  // Get OneSignal player IDs for all users
  const users = await User.find({ _id: { $in: userIds } }).select(
    "oneSignalPlayerId"
  );
  const playerIds = users
    .filter((user) => user.oneSignalPlayerId)
    .map((user) => user.oneSignalPlayerId);

  if (playerIds.length === 0) {
    return next(
      new AppError(
        "No valid OneSignal player IDs found for the specified users",
        404
      )
    );
  }

  // Send the push notification
  const result = await oneSignalService.sendNotificationToUsers(
    playerIds,
    title,
    body,
    data
  );

  res.status(200).json({
    status: "success",
    message: "Push notification sent successfully",
    data: {
      recipients: playerIds.length,
      notificationId: result.body.id,
    },
  });
});
