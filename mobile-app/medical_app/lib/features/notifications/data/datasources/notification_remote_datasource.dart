import 'package:dartz/dartz.dart';
import 'package:medical_app/constants.dart';
import 'package:medical_app/core/error/exceptions.dart';
import 'package:medical_app/features/notifications/data/models/notification_model.dart';
import 'package:medical_app/features/notifications/domain/entities/notification_entity.dart';
import 'package:medical_app/features/notifications/domain/repositories/notification_repository.dart';
import 'package:medical_app/features/notifications/utils/notification_utils.dart';
import 'package:medical_app/features/notifications/utils/onesignal_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;

abstract class NotificationRemoteDataSource {
  /// Get all notifications for a specific user with pagination
  Future<List<NotificationModel>> getNotifications({
    int page = 1,
    int limit = 20,
    bool? unreadOnly,
    String? type,
  });

  /// Get unread notifications count
  Future<int> getUnreadNotificationsCount();

  /// Mark a notification as read
  Future<Unit> markNotificationAsRead(String notificationId);

  /// Mark all notifications as read
  Future<Unit> markAllNotificationsAsRead();

  /// Get notification preferences
  Future<NotificationPreferences> getNotificationPreferences();

  /// Update notification preferences
  Future<Unit> updateNotificationPreferences(NotificationPreferences preferences);

  /// Register device for push notifications
  Future<Unit> registerDevice({
    required String playerId,
    required String platform,
    String? deviceModel,
  });

  /// Unregister device from push notifications
  Future<Unit> unregisterDevice(String playerId);

  /// Delete a notification
  Future<Unit> deleteNotification(String notificationId);

  /// Initialize OneSignal
  Future<void> initializeOneSignal();

  /// Set external user ID after login
  Future<void> setExternalUserId(String userId);

  /// Get OneSignal player ID
  Future<String?> getOneSignalPlayerId();

  /// Save OneSignal player ID to the server
  Future<Unit> saveOneSignalPlayerId(String userId);

  /// Remove external user ID when logging out
  Future<void> logout();

  // Legacy method for backwards compatibility
  Future<Unit> sendNotification({
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

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final http.Client client;
  final OneSignalService oneSignalService;

  NotificationRemoteDataSourceImpl({
    required this.client,
    required this.oneSignalService,
  });

  // Helper method to get the auth token
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('TOKEN');
  }

  @override
  Future<void> initializeOneSignal() async {
    await oneSignalService.init();
  }

  @override
  Future<void> setExternalUserId(String userId) async {
    await oneSignalService.setExternalUserId(userId);
  }

  @override
  Future<String?> getOneSignalPlayerId() async {
    return await oneSignalService.getPlayerId();
  }

  @override
  Future<Unit> saveOneSignalPlayerId(String userId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw ServerException(message: 'Authentication token not found');
      }

      final playerId = await oneSignalService.getPlayerId();
      if (playerId == null) {
        throw ServerException(message: 'Failed to get OneSignal player ID');
      }

      // Use the new register-device endpoint
      final response = await client.post(
        Uri.parse('${AppConstants.notificationsEndpoint}/register-device'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'playerId': playerId,
          'platform': Platform.isIOS ? 'ios' : 'android',
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final errorBody = json.decode(response.body);
        throw ServerException(
          message: errorBody['message'] ?? 'Failed to save OneSignal player ID',
        );
      }

      return unit;
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Failed to save OneSignal player ID: $e');
    }
  }

  @override
  Future<void> logout() async {
    await oneSignalService.logout();
  }

  @override
  Future<List<NotificationModel>> getNotifications({
    int page = 1,
    int limit = 20,
    bool? unreadOnly,
    String? type,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw ServerException(message: 'Authentication token not found');
      }

      // Build query parameters
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (unreadOnly == true) {
        queryParams['unreadOnly'] = 'true';
      }
      if (type != null) {
        queryParams['type'] = type;
      }

      final uri = Uri.parse(AppConstants.notificationsEndpoint).replace(
        queryParameters: queryParams,
      );

      final response = await client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        final errorBody = json.decode(response.body);
        throw ServerException(
          message: errorBody['message'] ?? 'Failed to fetch notifications',
        );
      }

      final Map<String, dynamic> responseData = json.decode(response.body);
      final dynamic notificationsData = responseData['data']?['notifications'] ?? responseData['data'] ?? [];
      
      if (notificationsData is! List) {
        return [];
      }

      return notificationsData.map((notificationData) {
        return NotificationModel.fromJson(notificationData);
      }).toList();
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Failed to fetch notifications: $e');
    }
  }

  @override
  Future<int> getUnreadNotificationsCount() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw ServerException(message: 'Authentication token not found');
      }

      final response = await client.get(
        Uri.parse('${AppConstants.notificationsEndpoint}/unread-count'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        final errorBody = json.decode(response.body);
        throw ServerException(
          message:
              errorBody['message'] ??
              'Failed to get unread notifications count',
        );
      }

      final Map<String, dynamic> responseData = json.decode(response.body);
      return responseData['data']?['count'] as int? ?? responseData['count'] as int? ?? 0;
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(
        message: 'Failed to get unread notifications count: $e',
      );
    }
  }

  @override
  Future<Unit> markNotificationAsRead(String notificationId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw ServerException(message: 'Authentication token not found');
      }

      final response = await client.put(
        Uri.parse('${AppConstants.notificationsEndpoint}/$notificationId/read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        final errorBody = json.decode(response.body);
        throw ServerException(
          message:
              errorBody['message'] ?? 'Failed to mark notification as read',
        );
      }

      return unit;
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Failed to mark notification as read: $e');
    }
  }

  @override
  Future<Unit> markAllNotificationsAsRead() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw ServerException(message: 'Authentication token not found');
      }

      final response = await client.put(
        Uri.parse('${AppConstants.notificationsEndpoint}/mark-all-read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        final errorBody = json.decode(response.body);
        throw ServerException(
          message:
              errorBody['message'] ??
              'Failed to mark all notifications as read',
        );
      }

      return unit;
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(
        message: 'Failed to mark all notifications as read: $e',
      );
    }
  }

  @override
  Future<NotificationPreferences> getNotificationPreferences() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw ServerException(message: 'Authentication token not found');
      }

      final response = await client.get(
        Uri.parse('${AppConstants.notificationsEndpoint}/preferences'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        final errorBody = json.decode(response.body);
        throw ServerException(
          message: errorBody['message'] ?? 'Failed to get notification preferences',
        );
      }

      final Map<String, dynamic> responseData = json.decode(response.body);
      final prefsData = responseData['data']?['preferences'] ?? responseData['preferences'] ?? {};
      
      final Map<String, ChannelPreference> preferences = {};
      if (prefsData is Map) {
        prefsData.forEach((key, value) {
          if (value is Map) {
            preferences[key] = ChannelPreference(
              push: value['push'] as bool? ?? true,
              email: value['email'] as bool? ?? true,
              inApp: value['inApp'] as bool? ?? true,
            );
          }
        });
      }

      return NotificationPreferences(preferences: preferences);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Failed to get notification preferences: $e');
    }
  }

  @override
  Future<Unit> updateNotificationPreferences(NotificationPreferences preferences) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw ServerException(message: 'Authentication token not found');
      }

      final prefsMap = <String, dynamic>{};
      preferences.preferences.forEach((key, value) {
        prefsMap[key] = {
          'push': value.push,
          'email': value.email,
          'inApp': value.inApp,
        };
      });

      final response = await client.put(
        Uri.parse('${AppConstants.notificationsEndpoint}/preferences'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'preferences': prefsMap}),
      );

      if (response.statusCode != 200) {
        final errorBody = json.decode(response.body);
        throw ServerException(
          message: errorBody['message'] ?? 'Failed to update notification preferences',
        );
      }

      return unit;
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Failed to update notification preferences: $e');
    }
  }

  @override
  Future<Unit> registerDevice({
    required String playerId,
    required String platform,
    String? deviceModel,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw ServerException(message: 'Authentication token not found');
      }

      final body = <String, dynamic>{
        'playerId': playerId,
        'platform': platform,
      };
      if (deviceModel != null) {
        body['deviceModel'] = deviceModel;
      }

      final response = await client.post(
        Uri.parse('${AppConstants.notificationsEndpoint}/register-device'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final errorBody = json.decode(response.body);
        throw ServerException(
          message: errorBody['message'] ?? 'Failed to register device',
        );
      }

      return unit;
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Failed to register device: $e');
    }
  }

  @override
  Future<Unit> unregisterDevice(String playerId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw ServerException(message: 'Authentication token not found');
      }

      final response = await client.delete(
        Uri.parse('${AppConstants.notificationsEndpoint}/devices/$playerId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        final errorBody = json.decode(response.body);
        throw ServerException(
          message: errorBody['message'] ?? 'Failed to unregister device',
        );
      }

      return unit;
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Failed to unregister device: $e');
    }
  }

  @override
  Future<Unit> deleteNotification(String notificationId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw ServerException(message: 'Authentication token not found');
      }

      final response = await client.delete(
        Uri.parse('${AppConstants.notificationsEndpoint}/$notificationId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        final errorBody = json.decode(response.body);
        throw ServerException(
          message: errorBody['message'] ?? 'Failed to delete notification',
        );
      }

      return unit;
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Failed to delete notification: $e');
    }
  }

  // Legacy method for backwards compatibility
  @override
  Future<Unit> sendNotification({
    required String title,
    required String body,
    required String senderId,
    required String recipientId,
    required NotificationType type,
    String? appointmentId,
    String? prescriptionId,
    Map<String, dynamic>? data,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw ServerException(message: 'Authentication token not found');
      }

      final Map<String, dynamic> requestData = {
        'title': title,
        'body': body,
        'senderId': senderId,
        'recipientId': recipientId,
        'type': NotificationUtils.notificationTypeToString(type),
      };

      if (appointmentId != null) {
        requestData['appointmentId'] = appointmentId;
      }

      if (prescriptionId != null) {
        requestData['prescriptionId'] = prescriptionId;
      }

      if (data != null) {
        requestData['data'] = data;
      }

      final response = await client.post(
        Uri.parse(AppConstants.notificationsEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestData),
      );

      if (response.statusCode != 201 && response.statusCode != 200) {
        final errorBody = json.decode(response.body);
        throw ServerException(
          message: errorBody['message'] ?? 'Failed to send notification',
        );
      }

      return unit;
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Failed to send notification: $e');
    }
  }
}
