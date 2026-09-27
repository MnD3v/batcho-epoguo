import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Un membre d'un défi et ce qu'il a bu cette semaine.
class ChallengeMember {
  const ChallengeMember({
    required this.uid,
    required this.name,
    required this.week,
    required this.ml,
  });

  final String uid;
  final String name;

  /// Lundi de la semaine où [ml] a été compté.
  final String week;
  final int ml;

  Map<String, Object> toMap() => {'name': name, 'week': week, 'ml': ml};

  static ChallengeMember fromMap(String uid, Map<String, dynamic> m) =>
      ChallengeMember(
        uid: uid,
        name: m['name'] as String? ?? '?',
        week: m['week'] as String? ?? '',
        ml: (m['ml'] as num?)?.toInt() ?? 0,
      );
}

/// Défi entre amis : qui boit le plus cette semaine ?
class Challenge {
  const Challenge({
    required this.code,
    required this.name,
    required this.members,
  });

  final String code;
  final String name;
  final List<ChallengeMember> members;

  /// Classement de la semaine [week] (les retardataires comptent 0).
  List<ChallengeMember> ranking(String week) => [
        for (final m in members)
          m.week == week
              ? m
              : ChallengeMember(uid: m.uid, name: m.name, week: week, ml: 0),
      ]..sort((a, b) => b.ml.compareTo(a.ml));
}

class SocialException implements Exception {
  const SocialException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Parrainage et défis entre amis, sauvegardés en ligne.
abstract class SocialRepository {
  /// Code d'invitation de [uid] (créé la première fois).
  Future<String> referralCode(String uid, {String? existing});

  /// Utilise le code d'un ami ; renvoie l'uid du parrain.
  Future<String> redeemReferral({required String uid, required String code});

  /// Nombre d'amis qui ont utilisé le code de [uid].
  Future<int> referralCount(String uid);

  Future<Challenge> createChallenge({
    required String title,
    required ChallengeMember me,
  });

  Future<Challenge> joinChallenge({
    required String code,
    required ChallengeMember me,
  });

  Future<void> leaveChallenge({required String code, required String uid});

  Future<List<Challenge>> challenges(List<String> codes);

  /// Met à jour ses litres de la semaine dans chaque défi.
  Future<void> report(List<String> codes, ChallengeMember me);
}

const maxChallengeMembers = 20;
const referralBonusXp = 50;

/// Codes faciles à dicter (sans 0/O ni 1/I).
String newCode([Random? random]) {
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final r = random ?? Random.secure();
  return List.generate(6, (_) => alphabet[r.nextInt(alphabet.length)]).join();
}

String normalizeCode(String code) => code.trim().toUpperCase();

class FirestoreSocialRepository implements SocialRepository {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  @override
  Future<String> referralCode(String uid, {String? existing}) async {
    if (existing != null) return existing;
    for (var attempt = 0; attempt < 5; attempt++) {
      final code = newCode();
      final ref = _db.collection('referralCodes').doc(code);
      final created = await _db.runTransaction((tx) async {
        if ((await tx.get(ref)).exists) return false;
        tx.set(ref, {'uid': uid});
        return true;
      });
      if (created) return code;
    }
    throw const SocialException('Impossible de créer ton code. Réessaie.');
  }

  @override
  Future<String> redeemReferral({
    required String uid,
    required String code,
  }) async {
    final owner =
        await _db.collection('referralCodes').doc(normalizeCode(code)).get();
    final referrer = owner.data()?['uid'] as String?;
    if (referrer == null) {
      throw const SocialException('Ce code n\'existe pas.');
    }
    if (referrer == uid) {
      throw const SocialException('C\'est ton propre code !');
    }
    final ref = _db.collection('referrals').doc(uid);
    if ((await ref.get()).exists) {
      throw const SocialException('Tu as déjà utilisé un code.');
    }
    await ref.set({
      'referrer': referrer,
      'code': normalizeCode(code),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return referrer;
  }

  @override
  Future<int> referralCount(String uid) async {
    final result = await _db
        .collection('referrals')
        .where('referrer', isEqualTo: uid)
        .count()
        .get();
    return result.count ?? 0;
  }

  DocumentReference<Map<String, dynamic>> _challenge(String code) =>
      _db.collection('challenges').doc(normalizeCode(code));

  @override
  Future<Challenge> createChallenge({
    required String title,
    required ChallengeMember me,
  }) async {
    for (var attempt = 0; attempt < 5; attempt++) {
      final code = newCode();
      final ref = _challenge(code);
      final created = await _db.runTransaction((tx) async {
        if ((await tx.get(ref)).exists) return false;
        tx.set(ref, {
          'name': title,
          'owner': me.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'members': {me.uid: me.toMap()},
        });
        return true;
      });
      if (created) return Challenge(code: code, name: title, members: [me]);
    }
    throw const SocialException('Impossible de créer le défi. Réessaie.');
  }

  @override
  Future<Challenge> joinChallenge({
    required String code,
    required ChallengeMember me,
  }) async {
    final snapshot = await _challenge(code).get();
    final data = snapshot.data();
    if (data == null) throw const SocialException('Ce défi n\'existe pas.');
    final members = Map<String, dynamic>.from(data['members'] as Map? ?? {});
    if (!members.containsKey(me.uid) && members.length >= maxChallengeMembers) {
      throw const SocialException('Ce défi est complet (20 amis au plus).');
    }
    await _challenge(code).update({'members.${me.uid}': me.toMap()});
    return _toChallenge(snapshot.id, {
      ...data,
      'members': {...members, me.uid: me.toMap()},
    });
  }

  @override
  Future<void> leaveChallenge({required String code, required String uid}) =>
      _challenge(code).update({'members.$uid': FieldValue.delete()});

  @override
  Future<List<Challenge>> challenges(List<String> codes) async {
    final result = <Challenge>[];
    for (final code in codes) {
      final snapshot = await _challenge(code).get();
      final data = snapshot.data();
      if (data != null) result.add(_toChallenge(snapshot.id, data));
    }
    return result;
  }

  @override
  Future<void> report(List<String> codes, ChallengeMember me) async {
    for (final code in codes) {
      await _challenge(code).update({'members.${me.uid}': me.toMap()});
    }
  }

  static Challenge _toChallenge(String code, Map<String, dynamic> data) =>
      Challenge(
        code: code,
        name: data['name'] as String? ?? 'Défi',
        members: [
          for (final e in Map<String, dynamic>.from(
            data['members'] as Map? ?? {},
          ).entries)
            ChallengeMember.fromMap(
              e.key,
              Map<String, dynamic>.from(e.value as Map),
            ),
        ],
      );
}

/// Mode démo : tout reste sur le téléphone (un seul joueur).
class DemoSocialRepository implements SocialRepository {
  DemoSocialRepository(this._prefs, {Random? random}) : _random = random;

  final SharedPreferences _prefs;
  final Random? _random;

  Map<String, dynamic> _read(String key) {
    final raw = _prefs.getString(key);
    return raw == null ? {} : jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> _write(String key, Map<String, dynamic> value) =>
      _prefs.setString(key, jsonEncode(value));

  @override
  Future<String> referralCode(String uid, {String? existing}) async {
    if (existing != null) return existing;
    final codes = _read('demo_referral_codes');
    final code = newCode(_random);
    codes[code] = uid;
    await _write('demo_referral_codes', codes);
    return code;
  }

  @override
  Future<String> redeemReferral({
    required String uid,
    required String code,
  }) async {
    final referrer = _read('demo_referral_codes')[normalizeCode(code)];
    if (referrer == null) {
      throw const SocialException('Ce code n\'existe pas.');
    }
    if (referrer == uid) {
      throw const SocialException('C\'est ton propre code !');
    }
    final referrals = _read('demo_referrals');
    if (referrals.containsKey(uid)) {
      throw const SocialException('Tu as déjà utilisé un code.');
    }
    referrals[uid] = referrer;
    await _write('demo_referrals', referrals);
    return referrer as String;
  }

  @override
  Future<int> referralCount(String uid) async =>
      _read('demo_referrals').values.where((r) => r == uid).length;

  @override
  Future<Challenge> createChallenge({
    required String title,
    required ChallengeMember me,
  }) async {
    final all = _read('demo_challenges');
    final code = newCode(_random);
    all[code] = {
      'name': title,
      'members': {me.uid: me.toMap()},
    };
    await _write('demo_challenges', all);
    return Challenge(code: code, name: title, members: [me]);
  }

  @override
  Future<Challenge> joinChallenge({
    required String code,
    required ChallengeMember me,
  }) async {
    final all = _read('demo_challenges');
    final data = all[normalizeCode(code)] as Map<String, dynamic>?;
    if (data == null) throw const SocialException('Ce défi n\'existe pas.');
    (data['members'] as Map<String, dynamic>)[me.uid] = me.toMap();
    await _write('demo_challenges', all);
    return (await challenges([normalizeCode(code)])).single;
  }

  @override
  Future<void> leaveChallenge(
      {required String code, required String uid}) async {
    final all = _read('demo_challenges');
    (all[code]?['members'] as Map<String, dynamic>?)?.remove(uid);
    await _write('demo_challenges', all);
  }

  @override
  Future<List<Challenge>> challenges(List<String> codes) async {
    final all = _read('demo_challenges');
    return [
      for (final code in codes)
        if (all[code] case final Map<String, dynamic> data)
          Challenge(
            code: code,
            name: data['name'] as String,
            members: [
              for (final e in (data['members'] as Map<String, dynamic>).entries)
                ChallengeMember.fromMap(e.key, e.value as Map<String, dynamic>),
            ],
          ),
    ];
  }

  @override
  Future<void> report(List<String> codes, ChallengeMember me) async {
    final all = _read('demo_challenges');
    for (final code in codes) {
      final members = all[code]?['members'] as Map<String, dynamic>?;
      if (members != null) members[me.uid] = me.toMap();
    }
    await _write('demo_challenges', all);
  }
}
