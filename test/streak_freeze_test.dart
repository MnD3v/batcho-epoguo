import 'package:bois_et_vis/data/hydration_store.dart';
import 'package:bois_et_vis/hydration_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

/// 5 alertes cochées : la flamme tient (5/7 = 70 %).
const _kept = ['420:250', '540:250', '660:250', '780:250', '900:250'];

String _key(int day) => 'checks_2026-09-${day.toString().padLeft(2, '0')}';

Future<HydrationController> _controller(Map<String, Object> extra) async {
  SharedPreferences.setMockInitialValues({
    ...setUpPrefs,
    'first_day': '2026-09-01',
    ...extra,
  });
  return HydrationController(
    store: await HydrationStore.load(),
    scheduler: FakeScheduler(),
    clock: () => DateTime(2026, 9, 27, 20),
  );
}

void main() {
  test('7 jours de flamme : palier fêté et jour de repos gagné', () async {
    final c = await _controller({
      for (var d = 21; d <= 26; d++) _key(d): _kept,
    });
    expect(c.streak, 6);
    expect(c.freezes, 0);

    late final List rewards = [];
    for (final r in c.reminders.take(5)) {
      rewards.add(await c.toggle(r));
    }
    expect(c.streak, 7);
    expect(c.freezes, 1);
    expect(rewards.last.freezeEarned, isTrue);
    expect(rewards.last.streakMilestone, 7);
    expect(rewards.last.worthCelebrating, isTrue);

    // Décocher puis recocher ne redonne pas de jour de repos.
    await c.toggle(c.reminders[4]);
    final again = await c.toggle(c.reminders[4]);
    expect(again.freezeEarned, isFalse);
    expect(c.freezes, 1);
  });

  test('un jour oublié est protégé par un jour de repos', () async {
    final c = await _controller({
      'stats_freezes': 1,
      for (var d = 23; d <= 25; d++) _key(d): _kept,
      // Le 26 est oublié.
    });
    expect(c.streak, 0);
    await c.protectStreak();
    expect(c.frozenNotice, 1);
    expect(c.freezes, 0);
    // Le jour de repos garde la série sans la faire grandir.
    expect(c.streak, 3);
    c.clearFrozenNotice();
    expect(c.frozenNotice, 0);
  });

  test('deux jours oubliés avec un seul jour de repos : série perdue',
      () async {
    final c = await _controller({
      'stats_freezes': 1,
      for (var d = 22; d <= 24; d++) _key(d): _kept,
    });
    await c.protectStreak();
    expect(c.frozenNotice, 0);
    expect(c.freezes, 1);
    expect(c.streak, 0);
  });

  test('rien à protéger si la flamme était déjà éteinte', () async {
    final c = await _controller({'stats_freezes': 2});
    await c.protectStreak();
    expect(c.freezes, 2);
  });
}
