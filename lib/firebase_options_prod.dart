// File generated for PROD environment
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps in PROD environment.
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

  // Configuración actual de producción
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBcn6fqwMYS2IaeRPudu3TwE3SMLj-z0QA',
    appId: '1:881860938861:web:2fd1afd78c0023b321c364',
    messagingSenderId: '881860938861',
    projectId: 'gestionpedidos-dd5ee',
    authDomain: 'gestionpedidos-dd5ee.firebaseapp.com',
    storageBucket: 'gestionpedidos-dd5ee.firebasestorage.app',
    measurementId: 'G-2VTWD7YGD3',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCbRH6sK2W7jrvTzsAn2Nvh8SrcKZe3N0s',
    appId: '1:881860938861:android:d96d74d57452c87e21c364',
    messagingSenderId: '881860938861',
    projectId: 'gestionpedidos-dd5ee',
    storageBucket: 'gestionpedidos-dd5ee.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBSTjdllEMe1oaD-ghPgxQBpqpZwpCdyBo',
    appId: '1:881860938861:ios:87ab5333326d0d4121c364',
    messagingSenderId: '881860938861',
    projectId: 'gestionpedidos-dd5ee',
    storageBucket: 'gestionpedidos-dd5ee.firebasestorage.app',
    iosBundleId: 'com.example.restauranteApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBSTjdllEMe1oaD-ghPgxQBpqpZwpCdyBo',
    appId: '1:881860938861:ios:87ab5333326d0d4121c364',
    messagingSenderId: '881860938861',
    projectId: 'gestionpedidos-dd5ee',
    storageBucket: 'gestionpedidos-dd5ee.firebasestorage.app',
    iosBundleId: 'com.example.restauranteApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBcn6fqwMYS2IaeRPudu3TwE3SMLj-z0QA',
    appId: '1:881860938861:web:b2df72336bfd46ed21c364',
    messagingSenderId: '881860938861',
    projectId: 'gestionpedidos-dd5ee',
    authDomain: 'gestionpedidos-dd5ee.firebaseapp.com',
    storageBucket: 'gestionpedidos-dd5ee.firebasestorage.app',
    measurementId: 'G-JFL42L1F18',
  );
}
