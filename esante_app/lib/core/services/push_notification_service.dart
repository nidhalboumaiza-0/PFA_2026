import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../../injection_container.dart';
import '../network/api_client.dart';
import '../network/api_list.dart';

/// Service to handle OneSignal push notifications
class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  // OneSignal App ID from backend config
  static const String _oneSignalAppId = 'b7f38ec8-6bd1-468b-bf40-8bd991871561';
  
  ApiClient? _apiClient;
  String? _playerId;
  bool _isInitialized = false;

  // Stream controllers for notification events
  final _notificationReceivedController = StreamController<OSNotification>.broadcast();
  final _notificationClickedController = StreamController<OSNotificationClickEvent>.broadcast();

  Stream<OSNotification> get onNotificationReceived => _notificationReceivedController.stream;
  Stream<OSNotificationClickEvent> get onNotificationClicked => _notificationClickedController.stream;

  String? get playerId => _playerId;
  bool get isInitialized => _isInitialized;

  /// Initialize OneSignal SDK
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Enable verbose logging in debug mode
      if (kDebugMode) {
        OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      }

      // Initialize OneSignal
      OneSignal.initialize(_oneSignalAppId);

      // Request notification permission
      await OneSignal.Notifications.requestPermission(true);

      // Set up notification handlers
      _setupNotificationHandlers();

      // Get player ID
      await _fetchPlayerId();

      _isInitialized = true;
      debugPrint('✅ OneSignal initialized successfully');
    } catch (e) {
      debugPrint('❌ OneSignal initialization failed: $e');
    }
  }

  /// Setup notification event handlers
  void _setupNotificationHandlers() {
    // When notification is received while app is in foreground
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      debugPrint('📬 Notification received in foreground: ${event.notification.title}');
      
      // Display the notification
      event.notification.display();
      
      // Emit to stream
      _notificationReceivedController.add(event.notification);
    });

    // When notification is clicked/opened
    OneSignal.Notifications.addClickListener((event) {
      debugPrint('👆 Notification clicked: ${event.notification.title}');
      
      // Emit to stream for handling navigation
      _notificationClickedController.add(event);
      
      // Handle notification data
      _handleNotificationClick(event);
    });

    // Permission change listener
    OneSignal.Notifications.addPermissionObserver((granted) {
      debugPrint('🔔 Notification permission changed: $granted');
    });

    // Subscription change listener
    OneSignal.User.pushSubscription.addObserver((state) {
      debugPrint('📱 Push subscription changed: ${state.current.id}');
      _playerId = state.current.id;
    });
  }

  /// Fetch and store player ID
  Future<void> _fetchPlayerId() async {
    try {
      // Wait a bit for OneSignal to register
      await Future.delayed(const Duration(seconds: 2));
      
      _playerId = OneSignal.User.pushSubscription.id;
      debugPrint('📱 OneSignal Player ID: $_playerId');
    } catch (e) {
      debugPrint('❌ Failed to get player ID: $e');
    }
  }

  /// Get or create ApiClient - use dependency injection for proper auth
  ApiClient get _api {
    // Use the injected ApiClient which has auth interceptor configured
    _apiClient ??= sl<ApiClient>();
    return _apiClient!;
  }

  /// Register device with backend for push notifications
  Future<bool> registerDeviceWithBackend() async {
    // Wait for player ID if not available yet
    if (_playerId == null || _playerId!.isEmpty) {
      debugPrint('⏳ Waiting for OneSignal player ID...');
      await _fetchPlayerId();
      
      // Still no player ID after waiting
      if (_playerId == null || _playerId!.isEmpty) {
        debugPrint('⚠️ Cannot register device: No player ID available');
        return false;
      }
    }

    debugPrint('📱 Registering device with player ID: $_playerId');

    try {
      await _api.post(
        ApiList.registerDevice,
        data: {
          'oneSignalPlayerId': _playerId,
          'deviceType': 'mobile',
          'platform': defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
        },
      );
      debugPrint('✅ Device registered with backend');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to register device with backend: $e');
      return false;
    }
  }

  /// Unregister device from backend
  Future<bool> unregisterDeviceFromBackend() async {
    if (_playerId == null || _playerId!.isEmpty) {
      return false;
    }

    try {
      await _api.delete('${ApiList.unregisterDevice}/$_playerId');
      debugPrint('✅ Device unregistered from backend');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to unregister device: $e');
      return false;
    }
  }

  /// Set external user ID (for targeting specific users)
  Future<void> setExternalUserId(String userId) async {
    try {
      OneSignal.login(userId);
      debugPrint('✅ External user ID set: $userId');
    } catch (e) {
      debugPrint('❌ Failed to set external user ID: $e');
    }
  }

  /// Remove external user ID (on logout)
  Future<void> removeExternalUserId() async {
    try {
      OneSignal.logout();
      debugPrint('✅ External user ID removed');
    } catch (e) {
      debugPrint('❌ Failed to remove external user ID: $e');
    }
  }

  /// Set user tags for segmentation
  Future<void> setUserTags(Map<String, String> tags) async {
    try {
      OneSignal.User.addTags(tags);
      debugPrint('✅ User tags set: $tags');
    } catch (e) {
      debugPrint('❌ Failed to set user tags: $e');
    }
  }

  /// Handle notification click based on data
  void _handleNotificationClick(OSNotificationClickEvent event) {
    final data = event.notification.additionalData;
    if (data == null) return;

    final type = data['type'] as String?;
    final resourceId = data['resourceId'] as String?;

    debugPrint('🔔 Notification type: $type, resourceId: $resourceId');

    // Navigation will be handled by the app based on the stream
    // The main app can listen to onNotificationClicked stream
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    return OneSignal.Notifications.permission;
  }

  /// Request notification permission
  Future<bool> requestPermission() async {
    return await OneSignal.Notifications.requestPermission(true);
  }

  /// Dispose streams
  void dispose() {
    _notificationReceivedController.close();
    _notificationClickedController.close();
  }
}
