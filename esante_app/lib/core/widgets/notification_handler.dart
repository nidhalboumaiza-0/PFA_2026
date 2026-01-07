import 'dart:async';
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../services/push_notification_service.dart';

/// Widget that handles push notification navigation
/// 
/// Wrap your main app content with this widget to handle
/// push notification navigation when the user clicks on a notification.
class NotificationHandler extends StatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  const NotificationHandler({
    super.key,
    required this.child,
    required this.navigatorKey,
  });

  @override
  State<NotificationHandler> createState() => _NotificationHandlerState();
}

class _NotificationHandlerState extends State<NotificationHandler> {
  late final PushNotificationService _pushService;
  StreamSubscription<OSNotificationClickEvent>? _clickSubscription;
  StreamSubscription<OSNotification>? _receivedSubscription;

  @override
  void initState() {
    super.initState();
    _pushService = PushNotificationService();
    _setupListeners();
  }

  @override
  void dispose() {
    _clickSubscription?.cancel();
    _receivedSubscription?.cancel();
    super.dispose();
  }

  void _setupListeners() {
    // Listen for notification clicks
    _clickSubscription = _pushService.onNotificationClicked.listen((event) {
      _handleNotificationClick(event);
    });

    // Listen for notifications received in foreground
    _receivedSubscription = _pushService.onNotificationReceived.listen((notification) {
      _showInAppNotification(notification);
    });
  }

  void _handleNotificationClick(OSNotificationClickEvent event) {
    final data = event.notification.additionalData;
    if (data == null) return;

    final type = data['type'] as String?;
    final resourceId = data['resourceId'] as String?;

    debugPrint('🔔 Handling notification click: type=$type, resourceId=$resourceId');

    // Navigate based on notification type
    switch (type) {
      case 'appointment_confirmed':
      case 'appointment_rejected':
      case 'appointment_cancelled':
      case 'appointment_reminder':
        _navigateToAppointment(resourceId);
        break;
      case 'new_message':
        _navigateToChat(resourceId, data);
        break;
      case 'referral_received':
      case 'referral_scheduled':
        _navigateToReferral(resourceId);
        break;
      case 'prescription_created':
      case 'consultation_created':
        _navigateToMedicalRecords(resourceId);
        break;
      default:
        // Navigate to notifications screen
        _navigateToNotifications();
    }
  }

  void _navigateToAppointment(String? appointmentId) {
    if (appointmentId == null) {
      // Navigate to appointments list
      widget.navigatorKey.currentState?.pushNamed('/appointments');
    } else {
      // Navigate to specific appointment
      widget.navigatorKey.currentState?.pushNamed(
        '/appointment-details',
        arguments: {'appointmentId': appointmentId},
      );
    }
  }

  void _navigateToChat(String? conversationId, Map<String, dynamic> data) {
    if (conversationId == null) {
      widget.navigatorKey.currentState?.pushNamed('/messages');
    } else {
      widget.navigatorKey.currentState?.pushNamed(
        '/chat',
        arguments: {
          'conversationId': conversationId,
          'recipientId': data['senderId'],
          'recipientName': data['senderName'] ?? 'User',
        },
      );
    }
  }

  void _navigateToReferral(String? referralId) {
    widget.navigatorKey.currentState?.pushNamed('/referrals');
  }

  void _navigateToMedicalRecords(String? resourceId) {
    widget.navigatorKey.currentState?.pushNamed('/medical-records');
  }

  void _navigateToNotifications() {
    widget.navigatorKey.currentState?.pushNamed('/notifications');
  }

  void _showInAppNotification(OSNotification notification) {
    if (!mounted) return;

    // Show a snackbar for in-app notifications
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.title ?? 'Notification',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (notification.body != null)
              Text(
                notification.body!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            _navigateToNotifications();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
