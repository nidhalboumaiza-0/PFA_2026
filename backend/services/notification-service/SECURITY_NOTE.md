# Security Note: OneSignal Dependencies

## Issue
The `onesignal-node` package (v3.4.0) has 6 vulnerabilities due to its dependency on the deprecated `request` package:
- 2 critical vulnerabilities in `form-data`
- 4 moderate vulnerabilities in `tough-cookie`

## Status
- These vulnerabilities are in the OneSignal SDK itself, not our code
- OneSignal has not updated the Node.js SDK to remove the `request` dependency
- The vulnerabilities are related to form data boundary generation and cookie parsing

## Alternatives

### Option 1: Use OneSignal REST API Directly (Recommended)
Instead of using `onesignal-node`, call OneSignal REST API directly with `axios`:

```javascript
// src/services/pushNotificationService.js (alternative implementation)
import axios from 'axios';

const ONESIGNAL_API_URL = 'https://onesignal.com/api/v1/notifications';

export const sendPushNotification = async (userId, notification) => {
  try {
    const preferences = await NotificationPreference.findOne({ userId });
    if (!preferences || preferences.devices.length === 0) {
      return { sent: false, error: 'No devices registered' };
    }

    const playerIds = preferences.getPlayerIds();
    const priorityMap = { low: 3, medium: 5, high: 8, urgent: 10 };

    const response = await axios.post(
      ONESIGNAL_API_URL,
      {
        app_id: process.env.ONESIGNAL_APP_ID,
        include_player_ids: playerIds,
        headings: { en: notification.title },
        contents: { en: notification.body },
        data: notification.actionData || {},
        priority: priorityMap[notification.priority] || 5,
        url: notification.actionUrl,
      },
      {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Basic ${process.env.ONESIGNAL_REST_API_KEY}`,
        },
      }
    );

    return {
      sent: true,
      oneSignalId: response.data.id,
      sentAt: new Date(),
    };
  } catch (error) {
    return {
      sent: false,
      error: error.message,
    };
  }
};
```

### Option 2: Use OneSignal Server SDK (@onesignal/node-onesignal)
OneSignal has a newer TypeScript-based SDK that doesn't use `request`:

```bash
npm uninstall onesignal-node
npm install @onesignal/node-onesignal
```

```javascript
import * as OneSignalSDK from '@onesignal/node-onesignal';

const client = new OneSignalSDK.DefaultApi(
  OneSignalSDK.createConfiguration({
    restApiKey: process.env.ONESIGNAL_REST_API_KEY,
  })
);

const notification = new OneSignalSDK.Notification();
notification.app_id = process.env.ONESIGNAL_APP_ID;
notification.include_player_ids = playerIds;
notification.headings = { en: title };
notification.contents = { en: body };

const response = await client.createNotification(notification);
```

### Option 3: Keep Current Implementation (Acceptable for Development)
- The vulnerabilities are in non-critical paths (form boundary generation)
- Risk is low for server-side usage
- Update to alternative when deploying to production

## Recommendation
- **Development**: Keep current implementation for now (works fine)
- **Production**: Migrate to Option 1 (direct REST API) or Option 2 (new SDK) before deployment

## Migration Priority
- Low urgency (development phase)
- High urgency (before production deployment)

---

**Note**: This does not affect the core functionality of the notification service. All features work as designed. The vulnerabilities are in the OneSignal SDK dependency chain, not in our application code.
