const express = require("express");
const notificationController = require("../controllers/notificationController");
const authController = require("../controllers/authController");

const router = express.Router();

// Protected routes
router.use(authController.protect);

// Get all notifications for the current user
router.get(
  "/my-notifications",
  notificationController.getNotifications
);

// Mark a notification as read
router.patch(
  "/mark-read/:id",
  notificationController.markNotificationAsRead
);

// Mark all notifications as read
router.patch(
  "/mark-all-read",
  notificationController.markAllNotificationsAsRead
);

// Delete a notification
router.delete("/:id", notificationController.deleteNotification);

// Get unread notifications count
router.get(
  "/unread-count",
  notificationController.getUnreadNotificationsCount
);

// Send push notification (admin only)
router.post(
  "/send-push",
  authController.restrictTo("admin"),
  notificationController.sendPushNotification
);

module.exports = router;
 