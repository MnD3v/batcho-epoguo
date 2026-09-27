import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'data/hydration_store.dart';
import 'hydration_controller.dart';
import 'models/game.dart';
import 'services/social_repository.dart';

/// Onglet « Amis » : code d'invitation, parrainage et défis de la semaine.
class SocialController extends ChangeNotifier {
  SocialController({
    required this.repository,
    required this.hydration,
    required HydrationStore store,
  }) : _store = store {
    // Les litres de la semaine suivent chaque alerte cochée.
    hydration.addListener(_reportIfChanged);
  }

  final SocialRepository repository;
  final HydrationController hydration;
  final HydrationStore _store;

  List<Challenge> challenges = const [];
  bool loading = false;
  String? error;

  /// Vrai quand c'est le réseau qui manque (icône nuage triste).
  bool offline = false;
  int _reportedMl = -1;

  String? get referralCode => _store.referralCode;
  bool get alreadyReferred => _store.referredBy != null;
  bool get signedIn => hydration.uid != null;

  ChallengeMember get me => ChallengeMember(
        uid: hydration.uid ?? '',
        name: hydration.profile?.firstName ?? 'Moi',
        week: hydration.weekKey,
        ml: hydration.weekMl,
      );

  @override
  void dispose() {
    hydration.removeListener(_reportIfChanged);
    super.dispose();
  }

  /// Déconnexion : on oublie les défis affichés.
  void reset() {
    challenges = const [];
    error = null;
    _reportedMl = -1;
    notifyListeners();
  }

  /// Recharge les défis, envoie mes litres, et (si [credit]) récompense les
  /// amis invités depuis la dernière fois ; renvoie ces XP à fêter.
  Future<Reward?> refresh({bool credit = true}) async {
    final uid = hydration.uid;
    if (uid == null) return null;
    loading = true;
    error = null;
    offline = false;
    notifyListeners();
    Reward? reward;
    try {
      final code = await repository.referralCode(uid, existing: referralCode);
      await _store.setReferralCode(code);
      await repository.report(_store.challengeCodes, me);
      _reportedMl = me.ml;
      challenges = await repository.challenges(_store.challengeCodes);
      final invited = credit ? await repository.referralCount(uid) : 0;
      final newFriends = invited - _store.referralsCredited;
      if (credit && newFriends > 0) {
        await _store.setReferralsCredited(invited);
        reward = await hydration.addBonusXp(newFriends * referralBonusXp);
      }
    } catch (e) {
      debugPrint('Amis : $e');
      final code = e is FirebaseException ? e.code : null;
      offline =
          code == null || code == 'unavailable' || code == 'deadline-exceeded';
      error = switch (code) {
        null ||
        'unavailable' ||
        'deadline-exceeded' =>
          'Pas de connexion internet. Réessaie plus tard.',
        // Règles Firestore pas publiées ou base pas encore créée.
        'permission-denied' ||
        'not-found' ||
        'failed-precondition' =>
          'Les défis ne sont pas encore ouverts. Réessaie plus tard.',
        _ => 'Oups, un souci avec le serveur ($code). Réessaie plus tard.',
      };
    }
    loading = false;
    notifyListeners();
    return reward;
  }

  /// Utilise le code d'un ami : +50 XP tout de suite.
  Future<Reward> redeem(String code) async {
    await repository.redeemReferral(uid: hydration.uid!, code: code);
    await _store.setReferredBy(normalizeCode(code));
    notifyListeners();
    return hydration.addBonusXp(referralBonusXp);
  }

  Future<Challenge> create(String title) async {
    final challenge = await repository.createChallenge(
      title: title.trim().isEmpty ? 'Défi de la semaine' : title.trim(),
      me: me,
    );
    await _addCode(challenge.code);
    return challenge;
  }

  Future<Challenge> join(String code) async {
    final normalized = normalizeCode(code);
    final challenge = await repository.joinChallenge(code: normalized, me: me);
    await _addCode(normalized);
    return challenge;
  }

  Future<void> leave(String code) async {
    await repository.leaveChallenge(code: code, uid: me.uid);
    await _store.setChallengeCodes(
      [..._store.challengeCodes]..remove(code),
    );
    challenges = challenges.where((c) => c.code != code).toList();
    notifyListeners();
  }

  Future<void> _addCode(String code) async {
    final codes = _store.challengeCodes;
    if (!codes.contains(code)) {
      await _store.setChallengeCodes([...codes, code]);
    }
    challenges = await repository.challenges(_store.challengeCodes);
    notifyListeners();
  }

  void _reportIfChanged() {
    if (!signedIn || _store.challengeCodes.isEmpty) return;
    final current = me;
    if (current.ml == _reportedMl) return;
    _reportedMl = current.ml;
    repository
        .report(_store.challengeCodes, current)
        .catchError((Object e) => debugPrint('Défis : $e'));
  }
}
