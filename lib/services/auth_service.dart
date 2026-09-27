import 'package:flutter/foundation.dart';

/// La personne connectée.
class AppUser {
  const AppUser({required this.uid, required this.email, this.firstName});

  final String uid;
  final String email;
  final String? firstName;
}

/// Erreur de connexion, avec un message prêt à afficher.
class AuthException implements Exception {
  const AuthException(this.message, {this.needsPassword = false});

  final String message;

  /// Action sensible : il faut redonner son mot de passe.
  final bool needsPassword;

  @override
  String toString() => message;
}

/// Connexion et comptes (Firebase, ou le mode démo en attendant les clés).
abstract class AuthService {
  /// La personne connectée, ou null.
  ValueListenable<AppUser?> get user;

  /// Vrai en mode démo : comptes gardés sur le téléphone seulement.
  bool get isDemo;

  Future<AppUser> signUp({
    required String firstName,
    required String email,
    required String password,
  });

  Future<AppUser> signIn({required String email, required String password});

  Future<void> sendPasswordReset(String email);

  Future<void> updateFirstName(String firstName);

  Future<void> signOut();

  /// Vérifie le mot de passe, lance [beforeDelete] (effacer les données en
  /// ligne tant qu'on en a encore le droit), puis supprime le compte.
  Future<void> deleteAccount({
    required String password,
    Future<void> Function()? beforeDelete,
  });
}

const minPasswordLength = 6;
