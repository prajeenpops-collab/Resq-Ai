import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static const String _apiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: 'YOUR_FIREBASE_API_KEY',
  );

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: _apiKey,
    appId: '1:77506005514:android:c238979c83f6f8ceea2df3',
    messagingSenderId: '77506005514',
    projectId: 'resqai-fc260',
    storageBucket: 'resqai-fc260.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: _apiKey,
    appId: '1:77506005514:web:c238979c83f6f8ceea2df3',
    messagingSenderId: '77506005514',
    projectId: 'resqai-fc260',
    storageBucket: 'resqai-fc260.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: _apiKey,
    appId: '1:77506005514:ios:c238979c83f6f8ceea2df3',
    messagingSenderId: '77506005514',
    projectId: 'resqai-fc260',
    storageBucket: 'resqai-fc260.firebasestorage.app',
  );
}
