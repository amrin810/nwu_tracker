import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
      case TargetPlatform.windows:
        return windows;
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB_quaT0wOizTrB1n6JNkSB7shZjD6tbPc',
    appId: '1:549545881513:web:97849cbb548773791d1eb8',
    messagingSenderId: '549545881513',
    projectId: 'nwu-bus-tracking',
    authDomain: 'nwu-bus-tracking.firebaseapp.com',
    databaseURL: 'https://nwu-bus-tracking-default-rtdb.firebaseio.com',
    storageBucket: 'nwu-bus-tracking.firebasestorage.app',
    measurementId: 'G-2RB4L87L0M',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDTjk7roX0VhFhLHlzMn_l3l3qHy9xgUI4',
    appId: '1:549545881513:android:c36f27fdb318a5701d1eb8',
    messagingSenderId: '549545881513',
    projectId: 'nwu-bus-tracking',
    databaseURL: 'https://nwu-bus-tracking-default-rtdb.firebaseio.com',
    storageBucket: 'nwu-bus-tracking.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB_quaT0wOizTrB1n6JNkSB7shZjD6tbPc',
    appId: '1:549545881513:web:97849cbb548773791d1eb8',
    messagingSenderId: '549545881513',
    projectId: 'nwu-bus-tracking',
    databaseURL: 'https://nwu-bus-tracking-default-rtdb.firebaseio.com',
    storageBucket: 'nwu-bus-tracking.firebasestorage.app',
    iosBundleId: 'com.example.busTracking',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyB_quaT0wOizTrB1n6JNkSB7shZjD6tbPc',
    appId: '1:549545881513:web:97849cbb548773791d1eb8',
    messagingSenderId: '549545881513',
    projectId: 'nwu-bus-tracking',
    databaseURL: 'https://nwu-bus-tracking-default-rtdb.firebaseio.com',
    storageBucket: 'nwu-bus-tracking.firebasestorage.app',
    iosBundleId: 'com.example.busTracking',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyB_quaT0wOizTrB1n6JNkSB7shZjD6tbPc',
    appId: '1:549545881513:web:97849cbb548773791d1eb8',
    messagingSenderId: '549545881513',
    projectId: 'nwu-bus-tracking',
    authDomain: 'nwu-bus-tracking.firebaseapp.com',
    databaseURL: 'https://nwu-bus-tracking-default-rtdb.firebaseio.com',
    storageBucket: 'nwu-bus-tracking.firebasestorage.app',
  );
}
