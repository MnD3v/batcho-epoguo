import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service.dart';

/// Comptes gardés sur le téléphone, tant que Firebase n'est pas configuré.
/// Sert aussi aux tests. Les mots de passe ne sont pas protégés : ce mode
/// ne doit pas partir en production.
class DemoAuthService implements AuthService {
  DemoAuthService(this._prefs) {
    final uid = _prefs.getString(_currentKey);
    final account = uid == null ? null : _accounts[uid];
    if (account != null) _user.value = _toUser(uid!, account);
  }

  static Future<DemoAuthService> load() async =>
      DemoAuthService(await SharedPreferences.getInstance());

  final SharedPreferences _prefs;
  final _user = ValueNotifier<AppUser?>(null);

  static const _accountsKey = 'demo_accounts';
  static const _currentKey = 'demo_current_uid';

  @override
  ValueListenable<AppUser?> get user => _user;

  @override
  bool get isDemo => true;

  Map<String, Map<String, dynamic>> get _accounts {
    final raw = _prefs.getString(_accountsKey);
    if (raw == null) return {};
    return (jsonDecode(raw) as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)),
    );
  }

  Future<void> _saveAccounts(Map<String, Map<String, dynamic>> accounts) =>
      _prefs.setString(_accountsKey, jsonEncode(accounts));

  @override
  Future<AppUser> signUp({
    required String firstName,
    required String email,
    required String password,
  }) async {
    final normalized = email.trim().toLowerCase();
    final accounts = _accounts;
    if (accounts.values.any((a) => a['email'] == normalized)) {
      throw const AuthException(
        'Un compte existe déjà avec cet e-mail. Connecte-toi !',
      );
    }
    if (password.length < minPasswordLength) {
      throw const AuthException(
        'Mot de passe trop faible : $minPasswordLength caractères minimum.',
      );
    }
    final uid = 'demo-${DateTime.now().microsecondsSinceEpoch}';
    accounts[uid] = {
      'email': normalized,
      'password': password,
      'firstName': firstName.trim(),
    };
    await _saveAccounts(accounts);
    await _prefs.setString(_currentKey, uid);
    return _user.value = _toUser(uid, accounts[uid]!);
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final normalized = email.trim().toLowerCase();
    for (final entry in _accounts.entries) {
      if (entry.value['email'] == normalized &&
          entry.value['password'] == password) {
        await _prefs.setString(_currentKey, entry.key);
        return _user.value = _toUser(entry.key, entry.value);
      }
    }
    throw const AuthException('E-mail ou mot de passe incorrect.');
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    // Rien à envoyer en mode démo.
  }

  @override
  Future<void> updateFirstName(String firstName) async {
    final current = _user.value;
    if (current == null) return;
    final accounts = _accounts;
    accounts[current.uid]?['firstName'] = firstName.trim();
    await _saveAccounts(accounts);
    _user.value = _toUser(current.uid, accounts[current.uid]!);
  }

  @override
  Future<void> signOut() async {
    await _prefs.remove(_currentKey);
    _user.value = null;
  }

  @override
  Future<void> deleteAccount({
    required String password,
    Future<void> Function()? beforeDelete,
  }) async {
    final current = _user.value;
    if (current == null) return;
    if (_accounts[current.uid]?['password'] != password) {
      throw const AuthException('Mot de passe incorrect.');
    }
    await beforeDelete?.call();
    final accounts = _accounts..remove(current.uid);
    await _saveAccounts(accounts);
    await signOut();
  }

  static AppUser _toUser(String uid, Map<String, dynamic> a) => AppUser(
        uid: uid,
        email: a['email'] as String,
        firstName: a['firstName'] as String?,
      );
}
