// Replace the placeholder values below with generated Firebase configuration values.
// Use `flutterfire configure` or the Firebase console to generate platform-specific options.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
        return macos;
      case TargetPlatform.linux:
        return linux;
      case TargetPlatform.windows:
        return windows;
      default:
        throw UnsupportedError('DefaultFirebaseOptions are not supported for this platform.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA2hI4skMcFFaI9qIdqq4gurSxts2uMhLY',
    appId: '1:772067527039:web:f28371cfcbbb242b5cb24a',
    messagingSenderId: '772067527039',
    projectId: 'keyrecordpbscb',
    authDomain: 'keyrecordpbscb.firebaseapp.com',
    storageBucket: 'keyrecordpbscb.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBpcqMV59YUhQCEfj0EKBdNRuzgCz2OF_w',
    appId: '1:772067527039:android:61ee4e8b6a47dbb25cb24a',
    messagingSenderId: '772067527039',
    projectId: 'keyrecordpbscb',
    storageBucket: 'keyrecordpbscb.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDW6tsLKU5ZAeZUGOwBWn_Xdzx9BKMVVN8',
    appId: '1:772067527039:ios:9be447711745f44e5cb24a',
    messagingSenderId: '772067527039',
    projectId: 'keyrecordpbscb',
    storageBucket: 'keyrecordpbscb.firebasestorage.app',
    iosBundleId: 'com.example.keyRecord',
  );
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDW6tsLKU5ZAeZUGOwBWn_Xdzx9BKMVVN8',
    appId: '1:772067527039:ios:9be447711745f44e5cb24a',
    messagingSenderId: '772067527039',
    projectId: 'keyrecordpbscb',
    storageBucket: 'keyrecordpbscb.firebasestorage.app',
    iosBundleId: 'com.example.keyRecord',
  );
  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: '',
    appId: '',
    messagingSenderId: '',
    projectId: '',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyA2hI4skMcFFaI9qIdqq4gurSxts2uMhLY',
    appId: '1:772067527039:web:81365e5c6c806ba95cb24a',
    messagingSenderId: '772067527039',
    projectId: 'keyrecordpbscb',
    authDomain: 'keyrecordpbscb.firebaseapp.com',
    storageBucket: 'keyrecordpbscb.firebasestorage.app',
  );
}
