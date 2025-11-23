// File generated for DEV environment
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps in DEV environment.
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

  // Configuración para DEV (proyecto: restaurante-app-2b048)
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD3nJdtZ-979Wfb6Lk-gWAmRoJ6Vxg7Fg0',
    appId: '1:390834182049:web:CONFIGURE_WEB_APP_IN_FIREBASE',
    messagingSenderId: '390834182049',
    projectId: 'restaurante-app-2b048',
    authDomain: 'restaurante-app-2b048.firebaseapp.com',
    storageBucket: 'restaurante-app-2b048.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD3nJdtZ-979Wfb6Lk-gWAmRoJ6Vxg7Fg0',
    appId: '1:390834182049:android:9e495b156e075ccc8a9de0',
    messagingSenderId: '390834182049',
    projectId: 'restaurante-app-2b048',
    storageBucket: 'restaurante-app-2b048.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD3nJdtZ-979Wfb6Lk-gWAmRoJ6Vxg7Fg0',
    appId: '1:390834182049:ios:CONFIGURE_IOS_APP_IN_FIREBASE',
    messagingSenderId: '390834182049',
    projectId: 'restaurante-app-2b048',
    storageBucket: 'restaurante-app-2b048.firebasestorage.app',
    iosBundleId: 'com.example.restauranteApp.dev',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyD3nJdtZ-979Wfb6Lk-gWAmRoJ6Vxg7Fg0',
    appId: '1:390834182049:ios:CONFIGURE_IOS_APP_IN_FIREBASE',
    messagingSenderId: '390834182049',
    projectId: 'restaurante-app-2b048',
    storageBucket: 'restaurante-app-2b048.firebasestorage.app',
    iosBundleId: 'com.example.restauranteApp.dev',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyD3nJdtZ-979Wfb6Lk-gWAmRoJ6Vxg7Fg0',
    appId: '1:390834182049:web:CONFIGURE_WEB_APP_IN_FIREBASE',
    messagingSenderId: '390834182049',
    projectId: 'restaurante-app-2b048',
    authDomain: 'restaurante-app-2b048.firebaseapp.com',
    storageBucket: 'restaurante-app-2b048.firebasestorage.app',
  );
}
