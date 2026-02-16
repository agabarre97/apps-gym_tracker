// File generated manually from google-services.json values.
// Equivalent to what `flutterfire configure` produces.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    if (defaultTargetPlatform == TargetPlatform.android) return android;
    throw UnsupportedError(
      'DefaultFirebaseOptions have not been configured for '
      '${defaultTargetPlatform.name} – '
      'you can reconfigure this by running the FlutterFire CLI again.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDZvek0bYvvcM9VgUAwB9GYoO-GlgRprGo',
    appId: '1:333040356574:web:6ce4108db0140e7a1f064f',
    messagingSenderId: '333040356574',
    projectId: 'agabarre-gym-tracker',
    storageBucket: 'agabarre-gym-tracker.firebasestorage.app',
    authDomain: 'agabarre-gym-tracker.firebaseapp.com',
    databaseURL:
        'https://agabarre-gym-tracker-default-rtdb.europe-west1.firebasedatabase.app',
    measurementId: 'G-R0P210W433',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBzNDC8AsddzqUTFHIkKoUbnrsbpQWBDU4',
    appId: '1:333040356574:android:d983093173c006181f064f',
    messagingSenderId: '333040356574',
    projectId: 'agabarre-gym-tracker',
    storageBucket: 'agabarre-gym-tracker.firebasestorage.app',
  );
}
