# OneSignal Integration Guide

This guide explains how to set up OneSignal push notifications for
your medical app.

## 1. Creating a OneSignal Project

### Step 1: Create a OneSignal account

1. Go to [OneSignal's website](https://onesignal.com/)
2. Sign up for an account or log in if you already have one

### Step 2: Create a new app

1. From the OneSignal dashboard, click "New App/Website"
2. Enter your app name (e.g., "Medical App")
3. Select "Mobile App" as your platform

### Step 3: Configure your mobile platform

1. Choose "Flutter" as your SDK
2. Follow the platform-specific setup:

#### For Android:

1. Enter your Firebase Server Key and Sender ID
   - You'll need to create a Firebase project if you don't have one
   - Go to Firebase Console → Project Settings → Cloud Messaging to
     find these values
2. Enter your Google Project Number (also from Firebase)

#### For iOS:

1. Upload your Apple Push Notification Service (APNs) certificate
   - You'll need to create this in your Apple Developer account
   - Follow OneSignal's guide for creating an APNs certificate

### Step 4: Get your OneSignal App ID

1. After completing setup, you'll receive an App ID (a UUID)
2. Also get your REST API Key from the "Keys & IDs" section
3. Add these to your backend's .env file:
   ```
   ONESIGNAL_APP_ID=your-app-id
   ONESIGNAL_API_KEY=your-rest-api-key
   ```

## 2. Integrating OneSignal with Flutter

### Step 1: Add the OneSignal Flutter plugin

```bash
flutter pub add onesignal_flutter
```

### Step 2: Configure your Flutter app

#### In your main.dart file:

```dart
import 'package:onesignal_flutter/onesignal_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize OneSignal
  initOneSignal();

  runApp(MyApp());
}

void initOneSignal() {
  // Replace with your OneSignal App ID
  OneSignal.shared.setAppId("YOUR_ONESIGNAL_APP_ID");

  // Enable debug logs
  OneSignal.shared.setLogLevel(OSLogLevel.verbose, OSLogLevel.none);

  // Handle notification opened
  OneSignal.shared.setNotificationOpenedHandler((OSNotificationOpenedResult result) {
    // Handle notification opened here
    print('Notification opened: ${result.notification.additionalData}');

    // You can navigate to specific screens based on the data
    final data = result.notification.additionalData;
    if (data != null) {
      if (data['type'] == 'appointment') {
        // Navigate to appointment details
      } else if (data['type'] == 'prescription') {
        // Navigate to prescription details
      }
    }
  });

  // Handle notification will show in foreground
  OneSignal.shared.setNotificationWillShowInForegroundHandler((OSNotificationReceivedEvent event) {
    // Will be called whenever a notification is received in foreground
    print('Notification received in foreground');

    // Complete with null means show the notification
    event.complete(event.notification);
  });

  // Request permission (iOS)
  OneSignal.shared.promptUserForPushNotificationPermission();
}
```

### Step 3: Send the OneSignal Player ID to your backend

After initializing OneSignal, get the player ID and send it to your
backend:

```dart
void getAndSendOneSignalPlayerId() async {
  final status = await OneSignal.shared.getDeviceState();
  final playerId = status?.userId;

  if (playerId != null) {
    // Send to your backend
    try {
      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/users/updateOneSignalPlayerId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken'
        },
        body: jsonEncode({'oneSignalPlayerId': playerId}),
      );

      if (response.statusCode == 200) {
        print('OneSignal Player ID updated successfully');
      } else {
        print('Failed to update OneSignal Player ID');
      }
    } catch (e) {
      print('Error updating OneSignal Player ID: $e');
    }
  }
}
```

Call this function after user login and when the app starts if the
user is already logged in.

## 3. Testing Push Notifications

### From the OneSignal Dashboard:

1. Go to "Messages" → "New Push"
2. Create a test notification
3. Select your app and target specific users or segments
4. Send the notification and verify it's received on your device

### From your backend API:

Use the `/api/v1/notifications/send-push` endpoint (admin only):

```json
POST /api/v1/notifications/send-push
{
  "title": "Test Notification",
  "body": "This is a test notification",
  "userIds": ["userId1", "userId2"],
  "data": {
    "type": "appointment",
    "appointmentId": "123456"
  }
}
```

## 4. Advanced Features

### Segments

You can create user segments in OneSignal for targeted notifications:

1. Go to "Audience" → "Segments"
2. Create segments based on user properties, behavior, or tags

### Tags

You can add tags to users for better targeting:

```dart
// Add tags
OneSignal.shared.sendTag("role", "patient");
OneSignal.shared.sendTag("subscriptionStatus", "premium");

// Delete tags
OneSignal.shared.deleteTag("temporaryTag");
```

### In-App Messages

You can create in-app messages that don't appear in the notification
center:

1. Go to "Messages" → "New In-App"
2. Design your in-app message
3. Set triggers for when it should appear

## Troubleshooting

### Common Issues:

1. **Notifications not showing on Android**: Check your Firebase
   configuration
2. **Notifications not showing on iOS**: Verify your APNs certificate
3. **Player ID not being sent to backend**: Check network connectivity
   and authentication

### Debugging:

- Enable verbose logging in OneSignal
- Check the OneSignal dashboard for delivery reports
- Use the "All Users" section in OneSignal to verify player IDs are
  registered

For more information, refer to the
[OneSignal Flutter SDK documentation](https://documentation.onesignal.com/docs/flutter-sdk-setup).
