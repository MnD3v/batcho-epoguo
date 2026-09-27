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

  test('courbes : litres par jour et moyenne par mois', () async {
    SharedPreferences.setMockInitialValues({
      ...setUpPrefs,
      'first_day': '2026-08-30',
      'checks_2026-08-30': ['420:250', '540:250'], // 0,5 L
      'checks_2026-08-31': ['420:250'], // 0,25 L
      'checks_2026-09-26': ['420:250', '540:250', '660:250', '780:250'], // 1 L
    });
    final c = HydrationController(
      store: await HydrationStore.load(),
      scheduler: FakeScheduler(),
      clock: () => DateTime(2026, 9, 27, 21),
    );

    final days = c.lastDays(30);
    expect(days.length, 30);
    expect(days.last.date, DateTime(2026, 9, 27));
    expect(days.last.liters, 0);
    expect(days[28].liters, 1); // 26 septembre
    expect(days.first.date, DateTime(2026, 8, 29));
    expect(days.first.liters, isNull); // avant le premier jour
    expect(days[1].liters, 0.5);

    final months = c.lastMonths(12);
    expect(months.length, 12);
    expect(months.last.date, DateTime(2026, 9));
    expect(months.last.liters, closeTo(1 / 26, 1e-9)); // 1 L sur 26 jours finis
    expect(months[10].liters, closeTo(0.75 / 2, 1e-9)); // août : 2 jours
    expect(months.first.liters, isNull);
  });
}
