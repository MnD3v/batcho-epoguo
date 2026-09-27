import 'dart:math';

import 'package:bois_et_vis/data/hydration_store.dart';
import 'package:bois_et_vis/hydration_controller.dart';
import 'package:bois_et_vis/services/auth_service.dart';
import 'package:bois_et_vis/services/social_repository.dart';
import 'package:bois_et_vis/social_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

void main() {
  test('codes faciles à dicter', () {
    final code = newCode(Random(1));
    expect(code.length, 6);
    expect(RegExp(r'^[A-HJ-NP-Z2-9]{6}$').hasMatch(code), isTrue);
    expect(normalizeCode(' abc123 '), 'ABC123');
  });

  test('classement de la semaine', () {
    const challenge = Challenge(code: 'ABCDEF', name: 'Famille', members: [
      ChallengeMember(uid: 'a', name: 'Awa', week: '2026-09-21', ml: 3000),
      ChallengeMember(uid: 'k', name: 'Kofi', week: '2026-09-21', ml: 4500),
      // Pas encore mis à jour cette semaine : compte 0.
      ChallengeMember(uid: 'y', name: 'Yao', week: '2026-09-14', ml: 9000),
    ]);
    final ranking = challenge.ranking('2026-09-21');
    expect(ranking.map((m) => m.name), ['Kofi', 'Awa', 'Yao']);
    expect(ranking.last.ml, 0);
  });

  Future<SocialController> social(
    SharedPreferences prefs,
    String uid,
    String name,
  ) async {
    final c = HydrationController(
      store: HydrationStore(prefs),
      scheduler: FakeScheduler(),
      clock: () => DateTime(2026, 9, 27, 10, 15),
    );
    await c.onSignedIn(AppUser(uid: uid, email: '$uid@x.com', firstName: name));
    return SocialController(
      repository: DemoSocialRepository(prefs, random: Random(uid.hashCode)),
      hydration: c,
      store: HydrationStore(prefs),
    );
  }

  test('parrainage : +50 XP pour le filleul puis pour le parrain', () async {
    SharedPreferences.setMockInitialValues(setUpPrefs);
    final prefs = await SharedPreferences.getInstance();

    final awa = await social(prefs, 'awa', 'Awa');
    await awa.refresh();
    final code = awa.referralCode!;
    expect(awa.hydration.xp, 0);

    // Kofi utilise le code d'Awa (même téléphone en mode démo).
    final kofi = SocialController(
      repository: DemoSocialRepository(prefs),
      hydration: HydrationController(
        store: HydrationStore(prefs),
        scheduler: FakeScheduler(),
      )..onSignedIn(const AppUser(uid: 'kofi', email: 'k@x.com')),
      store: HydrationStore(prefs),
    );
    await Future<void>.delayed(Duration.zero);
    expect(
      () => kofi.redeem('ZZZZZZ'),
      throwsA(isA<SocialException>()),
    );
    final reward = await kofi.redeem(code.toLowerCase());
    expect(reward.xp, referralBonusXp);
    expect(kofi.alreadyReferred, isTrue);
    await expectLater(kofi.redeem(code), throwsA(isA<SocialException>()));

    // Awa reçoit son bonus à la prochaine ouverture, une seule fois.
    final demo = DemoSocialRepository(prefs);
    expect(await demo.referralCount('awa'), 1);
    expect(
      () => demo.redeemReferral(uid: 'awa', code: code),
      throwsA(isA<SocialException>()),
    );
  });

  test('défi : créer, rejoindre, litres de la semaine', () async {
    SharedPreferences.setMockInitialValues({
      ...setUpPrefs,
      'checks_2026-09-21': ['420:250', '540:250'], // lundi
      'checks_2026-09-20': ['420:250'], // dimanche d'avant : pas compté
    });
    final prefs = await SharedPreferences.getInstance();
    final awa = await social(prefs, 'awa', 'Awa');
    expect(awa.me.week, '2026-09-21');
    expect(awa.me.ml, 500);

    final challenge = await awa.create('Famille');
    expect(awa.challenges.single.name, 'Famille');

    final repo = DemoSocialRepository(prefs);
    await repo.joinChallenge(
      code: challenge.code.toLowerCase(),
      me: const ChallengeMember(
          uid: 'kofi', name: 'Kofi', week: '2026-09-21', ml: 750),
    );
    await awa.refresh();
    final ranking = awa.challenges.single.ranking(awa.me.week);
    expect(ranking.map((m) => m.name), ['Kofi', 'Awa']);

    // Cocher une alerte met à jour ses litres dans le défi.
    await awa.hydration.toggle(awa.hydration.reminders[1]);
    await Future<void>.delayed(Duration.zero);
    final updated = (await repo.challenges([challenge.code])).single;
    expect(updated.members.firstWhere((m) => m.uid == 'awa').ml, 750);

    await awa.leave(challenge.code);
    expect(awa.challenges, isEmpty);
  });
}
