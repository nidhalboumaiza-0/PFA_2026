import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/features/notifications/domain/entities/notification_entity.dart';

/// Notification preferences entity
class NotificationPreferences {
  final Map<String, ChannelPreference> preferences;

  const NotificationPreferences({required this.preferences});
}

class ChannelPreference {
  final bool push;
  final bool email;
  final bool inApp;

  const ChannelPreference({
    this.push = true,
    this.email = true,
    this.inApp = true,
  });
}

abstract class NotificationRepository {
  /// Get all notifications for the current user with optional pagination
  Future<Either<Failure, List<NotificationEntity>>> getNotifications({
    int page = 1,
    int limit = 20,
    bool? unreadOnly,
    String? type,
  });

  /// Get unread notifications count
  Future<Either<Failure, int>> getUnreadNotificationsCount();

  /// Mark a notification as read
  Future<Either<Failure, Unit>> markNotificationAsRead(String notificationId);

  /// Mark all notifications as read for the current user
  Future<Either<Failure, Unit>> markAllNotificationsAsRead();

  /// Get notification preferences
  Future<Either<Failure, NotificationPreferences>> getNotificationPreferences();

  /// Update notification preferences
  Future<Either<Failure, Unit>> updateNotificationPreferences(
    NotificationPreferences preferences,
  );

  /// Register device for push notifications
  Future<Either<Failure, Unit>> registerDevice({
    required String playerId,
    required String platform,
    String? deviceModel,
  });

  /// Unregister device from push notifications
  Future<Either<Failure, Unit>> unregisterDevice(String playerId);

  /// Delete a notification
  Future<Either<Failure, Unit>> deleteNotification(String notificationId);

  // OneSignal specific methods
  /// Initialize OneSignal
  Future<Either<Failure, Unit>> initializeOneSignal();

  /// Set external user ID for OneSignal
  Future<Either<Failure, Unit>> setExternalUserId(String userId);

  /// Get OneSignal player ID
  Future<Either<Failure, String?>> getOneSignalPlayerId();

  /// Save OneSignal player ID to the backend
  Future<Either<Failure, Unit>> saveOneSignalPlayerId(String userId);

  /// Clear OneSignal user data for logout
  Future<Either<Failure, Unit>> logout();

  // Legacy methods for backwards compatibility
  /// Send a notification
  Future<Either<Failure, Unit>> sendNotification({
    required String title,
    required String body,
    required String senderId,
    required String recipientId,
    required NotificationType type,
    String? appointmentId,
    String? prescriptionId,
    Map<String, dynamic>? data,
  });
}
