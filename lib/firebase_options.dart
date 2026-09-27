// Clés du projet Firebase « bois-et-vis ».
// Peut être régénéré avec `flutterfire configure --platforms=android,ios`.
// ignore_for_file: type=lint

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        // iOS : ajouter l'appli iOS dans la console Firebase, puis compléter
        // ici. En attendant, l'appli tourne en mode démo sur iPhone.
        throw UnsupportedError(
          'Firebase n\'est pas encore configuré pour $defaultTargetPlatform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCLK1djjE17639yRcDjyL8yzkwxR1bDsLM',
    appId: '1:566699798196:android:00846e07af2600d12d31e1',
    messagingSenderId: '566699798196',
    projectId: 'bois-et-vis',
    storageBucket: 'bois-et-vis.firebasestorage.app',
  );
}
