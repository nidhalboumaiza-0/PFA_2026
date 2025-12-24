# Admin Dashboard for Medical App

## Firebase Setup

This admin dashboard connects to the same Firebase project as the mobile Medical App. To properly set up Firebase for this web application:

1. **Add a web app to your existing Firebase project:**
   - Go to Firebase Console (https://console.firebase.google.com/)
   - Select your project "medicalapp-f1951"
   - Click on "+ Add app" and select the Web platform
   - Register your app with a name like "admin-dashboard-web"
   - Firebase will provide you with configuration values

2. **Update the web configuration in `lib/firebase_options.dart`:**
   - Replace the following placeholders with values from Firebase Console:
     - `appId`: Your web app ID (format: 1:347722856442:web:xxxxxxxxxxxx)
     - `authDomain`: Your auth domain (typically projectId.firebaseapp.com)
     - `measurementId`: Your Google Analytics measurement ID (format: G-XXXXXXXXXX)

## Running the Admin Dashboard

```bash
cd admin-dashboard
flutter pub get
flutter run -d chrome
```

## Security Rules

Make sure to set up proper Firestore and Firebase Storage security rules to ensure that only admin users can access certain data and perform administrative operations.
