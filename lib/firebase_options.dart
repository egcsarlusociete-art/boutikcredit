import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android: return android;
      case TargetPlatform.iOS:     return ios;
      default: throw UnsupportedError('Plateforme non supportée.');
    }
  }

  // ── Android : récupérer dans google-services.json ──
  // Console Firebase → egcsarlu-app-b2ba4 → Ajouter app Android
  // Package name : com.boutikcredit.app
  // Télécharger google-services.json → copier dans android/app/
  static const FirebaseOptions android = FirebaseOptions(
    apiKey:            'AIzaSyAjKGNOv-cbv7PPN8vYPDf2eAOSuGLNVQQ',
    appId:             '1:695609211507:android:461499ea4c20493e2c8806',
    messagingSenderId: '695609211507',
    projectId:         'egcsarlu-app-b2ba4',
    storageBucket:     'egcsarlu-app-b2ba4.firebasestorage.app',
  );

  // ── iOS : récupérer dans GoogleService-Info.plist ──
  // Bundle ID : com.boutikcredit.app
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey:            'AIzaSyAjKGNOv-cbv7PPN8vYPDf2eAOSuGLNVQQ',
    appId:             '1:695609211507:ios:REMPLACER_APP_ID_IOS',
    messagingSenderId: '695609211507',
    projectId:         'egcsarlu-app-b2ba4',
    storageBucket:     'egcsarlu-app-b2ba4.firebasestorage.app',
    iosClientId:       'REMPLACER_IOS_CLIENT_ID',
    iosBundleId:       'com.boutikcredit.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey:            'AIzaSyAjKGNOv-cbv7PPN8vYPDf2eAOSuGLNVQQ',
    appId:             '1:695609211507:web:752cf32e9ee0b9882c8806',
    messagingSenderId: '695609211507',
    projectId:         'egcsarlu-app-b2ba4',
    storageBucket:     'egcsarlu-app-b2ba4.firebasestorage.app',
    measurementId:     'G-JDZGGJRHZT',
  );
}
