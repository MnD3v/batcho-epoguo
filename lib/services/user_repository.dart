import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sauvegarde en ligne des données de chaque personne : `users/{uid}`.
///
/// Le document garde en clair le prénom, l'e-mail et les réponses au
/// questionnaire (faciles à consulter dans la console Firebase), et dans
/// `data` tout ce qu'il faut pour retrouver sa progression sur un autre
/// téléphone.
abstract class UserRepository {
  Future<Map<String, dynamic>?> load(String uid);

  Future<void> save(String uid, Map<String, Object?> document);

  Future<void> delete(String uid);
}

class FirestoreUserRepository implements UserRepository {
  CollectionReference<Map<String, dynamic>> get _users =>
      FirebaseFirestore.instance.collection('users');

  @override
  Future<Map<String, dynamic>?> load(String uid) async =>
      (await _users.doc(uid).get()).data();

  @override
  Future<void> save(String uid, Map<String, Object?> document) =>
      _users.doc(uid).set({
        ...document,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  @override
  Future<void> delete(String uid) => _users.doc(uid).delete();
}

/// Mode démo : la « sauvegarde en ligne » reste sur le téléphone.
class DemoUserRepository implements UserRepository {
  DemoUserRepository(this._prefs);

  final SharedPreferences _prefs;

  String _key(String uid) => 'demo_cloud_$uid';

  @override
  Future<Map<String, dynamic>?> load(String uid) async {
    final raw = _prefs.getString(_key(uid));
    return raw == null ? null : jsonDecode(raw) as Map<String, dynamic>;
  }

  @override
  Future<void> save(String uid, Map<String, Object?> document) =>
      _prefs.setString(_key(uid), jsonEncode(document));

  @override
  Future<void> delete(String uid) => _prefs.remove(_key(uid));
}
