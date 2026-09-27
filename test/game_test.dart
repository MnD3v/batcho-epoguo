import 'package:bois_et_vis/data/hydration_store.dart';
import 'package:bois_et_vis/hydration_controller.dart';
import 'package:bois_et_vis/models/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

void main() {
  test('niveaux', () {
    expect(levelFor(0).name, 'Goutte');
    expect(levelFor(100).name, 'Flaque');
    expect(levelFor(99999).name, 'Océan');
    expect(nextLevel(levels.last), isNull);
  });

  test('journée parfaite : flamme, XP, niveau et badges', () async {
    SharedPreferences.setMockInitialValues({
      ...setUpPrefs,
      // Deux jours précédents validés (au moins 5 alertes sur 7).
      'checks_2026-09-25': [
        '420:250',
        '540:250',
        '660:250',
        '780:250',
        '900:250'
      ],
      'checks_2026-09-26': [
        '420:250',
        '540:250',
        '660:250',
        '780:250',
        '900:250'
      ],
    });
    final c = HydrationController(
      store: await HydrationStore.load(),
      scheduler: FakeScheduler(),
      clock: () => DateTime(2026, 9, 27, 21),
    );
    expect(c.streak, 2);
    expect(c.streakSafeToday, isFalse);
    expect(c.slotState(0), SlotState.missed);

    late Reward last;
    for (final r in c.reminders) {
      last = await c.toggle(r);
    }
    expect(c.streak, 3);
    expect(c.goalReached, isTrue);
    expect(c.drunkMl, 1750);
    expect(c.xp, 7 * xpPerCheck + xpPerfectDay);
    expect(last.goalReached, isTrue);
    expect(last.levelUp?.name, 'Flaque');
    expect(last.badges, contains(Achievement.perfectDay));
    expect(
      c.stats.badges,
      containsAll([
        Achievement.firstSip,
        Achievement.streak3,
        Achievement.earlyBird,
        Achievement.nightOwl,
      ]),
    );

    // Décocher retire les XP de la journée parfaite, mais garde les badges.
    final undo = await c.toggle(c.reminders.last);
    expect(undo.xp, -(xpPerCheck + xpPerfectDay));
    expect(c.stats.perfectDays, 0);
    expect(c.stats.badges, contains(Achievement.perfectDay));
    expect((await HydrationStore.load()).stats.totalMl, 1500);
  });

  test('états des étapes selon l\'heure', () async {
    SharedPreferences.setMockInitialValues(setUpPrefs);
    final c = HydrationController(
      store: await HydrationStore.load(),
      scheduler: FakeScheduler(),
      clock: () => DateTime(2026, 9, 27, 12, 30),
    );
    expect(c.slotState(0), SlotState.missed); // 7h
    expect(c.slotState(2), SlotState.current); // 11h
    expect(c.slotState(3), SlotState.locked); // 13h
    await c.toggle(c.reminders[0]);
    expect(c.slotState(0), SlotState.done);
  });
}
