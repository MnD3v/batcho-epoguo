import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'auth_service.dart';

class FirebaseAuthService implements AuthService {
  FirebaseAuthService() {
    _user.value = _toAppUser(_auth.currentUser);
    _auth.userChanges().listen((u) => _user.value = _toAppUser(u));
  }

  final _auth = FirebaseAuth.instance;
  final _user = ValueNotifier<AppUser?>(null);

  @override
  ValueListenable<AppUser?> get user => _user;

  @override
  bool get isDemo => false;

  @override
  Future<AppUser> signUp({
    required String firstName,
    required String email,
    required String password,
  }) =>
      _guard(() async {
        final result = await _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        await result.user!.updateDisplayName(firstName.trim());
        await result.user!.reload();
        return _user.value = _toAppUser(_auth.currentUser)!;
      });

  @override
  Future<AppUser> signIn({required String email, required String password}) =>
      _guard(() async {
        final result = await _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        return _user.value = _toAppUser(result.user)!;
      });

  @override
  Future<void> sendPasswordReset(String email) => _guard(() async {
        await _auth.setLanguageCode('fr');
        await _auth.sendPasswordResetEmail(email: email.trim());
      });

  @override
  Future<void> updateFirstName(String firstName) => _guard(() async {
        await _auth.currentUser?.updateDisplayName(firstName.trim());
        await _auth.currentUser?.reload();
        _user.value = _toAppUser(_auth.currentUser);
      });

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> deleteAccount({
    required String password,
    Future<void> Function()? beforeDelete,
  }) =>
      _guard(() async {
        final current = _auth.currentUser;
        if (current == null) return;
        await current.reauthenticateWithCredential(
          EmailAuthProvider.credential(
              email: current.email!, password: password),
        );
        await beforeDelete?.call();
        await current.delete();
      });

  static AppUser? _toAppUser(User? u) => u == null
      ? null
      : AppUser(uid: u.uid, email: u.email ?? '', firstName: u.displayName);

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        _messages[e.code] ?? 'Oups, une erreur est survenue (${e.code}).',
        needsPassword: e.code == 'requires-recent-login',
      );
    }
  }

  static const _messages = {
    'invalid-email': 'Cette adresse e-mail n\'est pas valide.',
    'user-disabled': 'Ce compte a été désactivé.',
    'user-not-found': 'E-mail ou mot de passe incorrect.',
    'user-mismatch': 'Mot de passe incorrect.',
    'wrong-password': 'E-mail ou mot de passe incorrect.',
    'invalid-credential': 'E-mail ou mot de passe incorrect.',
    'email-already-in-use':
        'Un compte existe déjà avec cet e-mail. Connecte-toi !',
    'weak-password':
        'Mot de passe trop faible : $minPasswordLength caractères minimum.',
    'too-many-requests': 'Trop d\'essais. Réessaie dans quelques minutes.',
    'network-request-failed': 'Pas de connexion internet. Vérifie ton réseau.',
    'requires-recent-login': 'Par sécurité, redonne ton mot de passe.',
    'operation-not-allowed':
        'La connexion par e-mail n\'est pas activée dans Firebase.',
  };
}
