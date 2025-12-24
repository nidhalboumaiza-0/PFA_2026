import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Web configuration with values provided by Firebase Console
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDJamW00Hmzxxp_4KgLSDJbEvApW1jTKMU',
    appId: '1:347722856442:web:4d1dd398b584b0db39d643',
    messagingSenderId: '347722856442',
    projectId: 'medicalapp-f1951',
    authDomain: 'medicalapp-f1951.firebaseapp.com',
    storageBucket: 'medicalapp-f1951.firebasestorage.app',
    measurementId: 'G-EJH6W9RL63',
  );

  // These values copied from the existing medical_app Firebase configuration
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA50ht7TJHLxub_-xWgoAGXUb4uulkVoXY',
    appId: '1:347722856442:android:e26f86c86d9fdb9d39d643',
    messagingSenderId: '347722856442',
    projectId: 'medicalapp-f1951',
    storageBucket: 'medicalapp-f1951.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDIgipdOjPAVmsThinIonZFjfz9wL-_Ew8',
    appId: '1:347722856442:ios:99766a27c6e967df39d643',
    messagingSenderId: '347722856442',
    projectId: 'medicalapp-f1951',
    storageBucket: 'medicalapp-f1951.firebasestorage.app',
    iosBundleId: 'com.example.medicalApp',
  );
}
