import 'package:dartz/dartz.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../constants.dart';
import '../../../core/error/exceptions.dart';

class OneSignalService {
  /// Initialize OneSignal with your app ID
  Future<void> init() async {
    // Initialize OneSignal
    OneSignal.initialize(AppConstants.oneSignalAppId);

    // Enable debug logs - remove in production
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

    // Request permission to send push notifications
    await OneSignal.Notifications.requestPermission(true);

    // Handle notification opened events
    OneSignal.Notifications.addClickListener((OSNotificationClickEvent event) {
      // Handle notification opened
      print('Notification opened: ${event.notification.notificationId}');

      // Handle additional data
      if (event.notification.additionalData != null) {
        print('Additional data: ${event.notification.additionalData}');
        // You can navigate to specific screens based on this data
      }
    });

    // Handle notification received in foreground
    OneSignal.Notifications.addForegroundWillDisplayListener((
      OSNotificationWillDisplayEvent event,
    ) {
      // Prevent the notification from displaying
      event.preventDefault();

      // You can handle the notification here and show it manually if needed
      print(
        'Notification received in foreground: ${event.notification.notificationId}',
      );

      // If you want to show the notification, you can do it manually
      // For example, using a custom notification UI
    });
  }

  /// Get OneSignal player ID (device token)
  Future<String?> getPlayerId() async {
    try {
      final deviceState = await OneSignal.User.pushSubscription;
      final playerId = deviceState.id;

      if (playerId != null) {
        // Save the player ID to SharedPreferences for future use
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('ONESIGNAL_PLAYER_ID', playerId);
      }

      return playerId;
    } catch (e) {
      print('Error getting OneSignal player ID: $e');
      return null;
    }
  }

  /// Save OneSignal player ID to backend
  Future<Unit> savePlayerIdToBackend(String userId) async {
    try {
      final playerId = await getPlayerId();
      if (playerId == null) {
        throw ServerException(message: 'Failed to get OneSignal player ID');
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('TOKEN');

      if (token == null) {
        throw ServerException(message: 'Authentication token not found');
      }

      // TODO: Update this to use the appropriate API endpoint from your backend
      // For now, we'll just return Unit since the actual implementation depends on your backend

      return unit;
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Failed to save OneSignal player ID: $e');
    }
  }

  /// Set external user ID (your app's user ID)
  Future<void> setExternalUserId(String userId) async {
    try {
      await OneSignal.login(userId);
    } catch (e) {
      print('Error setting external user ID: $e');
    }
  }

  /// Add tags to the user (for segmentation)
  Future<void> addTags(Map<String, dynamic> tags) async {
    try {
      await OneSignal.User.addTags(tags);
    } catch (e) {
      print('Error adding tags: $e');
    }
  }

  /// Remove tags from the user
  Future<void> removeTags(List<String> tagKeys) async {
    try {
      await OneSignal.User.removeTags(tagKeys);
    } catch (e) {
      print('Error removing tags: $e');
    }
  }

  /// Logout - clear external user ID
  Future<void> logout() async {
    try {
      await OneSignal.logout();
    } catch (e) {
      print('Error during OneSignal logout: $e');
    }
  }
}
