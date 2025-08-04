// lib/firebase_options.dart

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDYEQkVCRG9EjeEUGSg6Ks0_qut5D7J6Ps',
    appId: '1:383416517785:android:a92d37597fcb0a63d0e408',
    messagingSenderId: '383416517785',
    projectId: 'linda-shop-2835e',
    databaseURL: 'https://linda-shop-2835e-default-rtdb.firebaseio.com',
    storageBucket: 'linda-shop-2835e.firebasestorage.app',
  );
}
