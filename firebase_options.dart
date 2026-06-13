import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) throw UnsupportedError('Web not supported');
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
            'DefaultFirebaseOptions not supported for this platform.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAZJ0f7_Ky0i9XGFO4KOxOo4r9thC5Y8CM',
    appId: '1:972092271227:android:8c58dbc735fdfb359850de',
    messagingSenderId: '972092271227',
    projectId: 'naaro-cc497',
    storageBucket: 'naaro-cc497.firebasestorage.app',
  );
}
