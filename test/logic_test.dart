import 'package:bois_et_vis/data/hydration_store.dart';
import 'package:bois_et_vis/data/kidney_tips.dart';
import 'package:bois_et_vis/models/plan.dart';
import 'package:bois_et_vis/models/profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('formatLiters', () {
    expect(formatLiters(500), '0,5 L');
    expect(formatLiters(1750), '1,75 L');
    expect(formatLiters(2000), '2 L');
    expect(formatLiters(0), '0 L');
  });

  test('e-mail', () {
    expect(isValidEmail('awa@exemple.com'), isTrue);
    expect(isValidEmail(' awa@exemple.tg '), isTrue);
    expect(isValidEmail('awa@exemple'), isFalse);
    expect(isValidEmail('awa'), isFalse);
    expect(isValidEmail(''), isFalse);
  });

  test('alertes toutes les 2 h et toutes les 3 h, de 7h à 20h', () {
    final every2h = HydrationPlan.regular(Rhythm.every2h, 250);
    expect(every2h.reminders.map((r) => r.time), [
      '07:00',
      '09:00',
      '11:00',
      '13:00',
      '15:00',
      '17:00',
      '19:00',
    ]);
    expect(every2h.goalMl, 1750);
    final every3h = HydrationPlan.regular(Rhythm.every3h, 500);
    expect(every3h.reminders.map((r) => r.time), [
      '07:00',
      '10:00',
      '13:00',
      '16:00',
      '19:00',
    ]);
    expect(every3h.streakMinChecks, 4);
  });

  test('heures précises : triées, alerte en cours et suivante', () {
    final plan = HydrationPlan(Rhythm.custom, const [
      Reminder(12 * 60, 500),
      Reminder(9 * 60 + 30, 250),
      Reminder(18 * 60, 750),
    ]);
    expect(plan.reminders.map((r) => r.time), ['09:30', '12:00', '18:00']);
    expect(plan.goalMl, 1500);
    DateTime at(int h, int m) => DateTime(2026, 9, 27, h, m);
    expect(plan.currentIndex(at(9, 0)), isNull);
    expect(plan.nextIndex(at(9, 0)), 0);
    expect(plan.currentIndex(at(9, 30)), 0);
    expect(plan.currentIndex(at(12, 59)), 1);
    expect(plan.currentIndex(at(15, 30)), isNull); // plus de 3 h après
    expect(plan.nextIndex(at(15, 30)), 2);
    expect(plan.nextIndex(at(18, 0)), isNull);
  });

  test('chaque conseil est utilisé dans la semaine', () {
    final used = {
      for (var d = 1; d <= 7; d++)
        for (var s = 0; s < 7; s++) tipIndexFor(d, s),
    };
    expect(used.length, kidneyTips.length);
  });

  test('le stockage garde le profil, les alertes et les jours', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await HydrationStore.load();
    expect(store.profile, isNull);
    expect(store.plan, isNull);

    await store.saveProfile(const UserProfile(
      firstName: 'Awa',
      email: 'awa@exemple.com',
      usualIntake: UsualIntake.lessThan1L,
      difficulties: {Difficulty.forget, Difficulty.noWaterNearby},
    ));
    final profile = store.profile!;
    expect(profile.firstName, 'Awa');
    expect(profile.email, 'awa@exemple.com');
    expect(profile.usualIntake, UsualIntake.lessThan1L);
    expect(profile.difficulties, {Difficulty.forget, Difficulty.noWaterNearby});

    await store.savePlan(HydrationPlan(Rhythm.custom, const [
      Reminder(9 * 60, 500),
      Reminder(12 * 60, 500),
    ]));
    final plan = store.plan!;
    expect(plan.rhythm, Rhythm.custom);
    expect(plan.reminders, const [Reminder(540, 500), Reminder(720, 500)]);

    final day = DateTime(2026, 9, 27);
    await store.saveChecks(day, {540: 500});
    expect(store.checks(day), {540: 500});
    expect(store.checks(DateTime(2026, 9, 28)), isEmpty);

    // Les jours trop anciens sont supprimés.
    await store.saveChecks(DateTime(2027, 12, 31), {540: 500});
    expect(store.checks(day), isEmpty);
  });
}
