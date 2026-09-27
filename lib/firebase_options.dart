// Fichier provisoire : il sera remplacé par `flutterfire configure`, qui y
// écrit les clés du projet Firebase. Tant qu'il est là, l'appli tourne en
// mode démo (comptes gardés sur le téléphone).
// ignore_for_file: type=lint

import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => throw UnsupportedError(
        'Firebase n\'est pas encore configuré : lance `flutterfire configure`.',
      );
}
