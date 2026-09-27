import 'package:bois_et_vis/data/alert_messages.dart';
import 'package:bois_et_vis/data/hydration_store.dart';
import 'package:bois_et_vis/hydration_controller.dart';
import 'package:bois_et_vis/models/plan.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

void main() {
  test('les messages changent et le prix du rein revient souvent', () {
    final messages = [
      for (var slot = 0; slot < 7; slot++)
        alertMessage(
          firstName: 'Awa',
          reminder: const Reminder(540, 500),
          weekday: 1,
          slot: slot,
        ),
    ];
    expect(messages.map((m) => m.title).toSet().length, 4);
    expect(messages.every((m) => m.title.contains('Awa')), isTrue);
    expect(messages.every((m) => m.body.contains('0,5 L')), isTrue);
    expect(
      messages.where((m) => m.body.contains('15 000 000 FCFA')).length,
      greaterThanOrEqualTo(3),
    );
  });

  Future<(HydrationController, FakeScheduler)> at(
    int hour, [
    Map<String, Object> extra = const {},
  ]) async {
    SharedPreferences.setMockInitialValues({...setUpPrefs, ...extra});
    final scheduler = FakeScheduler();
    final c = HydrationController(
      store: await HydrationStore.load(),
      scheduler: scheduler,
      clock: () => DateTime(2026, 9, 27, hour),
    );
    return (c, scheduler);
  }

  test('alerte du soir si la flamme est en danger, annulée sinon', () async {
    final (c, scheduler) = await at(10, {
      'checks_2026-09-26': [
        '420:250',
        '540:250',
        '660:250',
        '780:250',
        '900:250'
      ],
    });
    // Dernière alerte à 19h → alerte du soir à 20h.
    expect(c.eveningRescueTime, DateTime(2026, 9, 27, 20));
    await c.updateEveningRescue();
    expect(scheduler.eveningAt, DateTime(2026, 9, 27, 20));
    expect(scheduler.eveningTitle, '🔥 Ta flamme de 1 jour est en danger !');

    // 5 alertes cochées sur 7 : la flamme est assurée, plus d'alerte du soir.
    for (final r in c.reminders.take(5)) {
      await c.toggle(r);
    }
    expect(c.streakSafeToday, isTrue);
    expect(scheduler.eveningAt, isNull);
  });

  test('pas d\'alerte du soir une fois l\'heure passée', () async {
    final (c, _) = await at(21);
    expect(c.eveningRescueTime, isNull);
  });

  test('son fort : enregistré et alertes reprogrammées', () async {
    final (c, scheduler) = await at(10);
    expect(c.loudAlerts, isFalse);
    await c.setLoudAlerts(true);
    expect(c.loudAlerts, isTrue);
    expect(scheduler.scheduledLoud, isTrue);
    expect((await HydrationStore.load()).loudAlerts, isTrue);
  });

  test('titres avec un emoji au début, visage qui change', () {
    const nine = Reminder(540, 500);
    final messages = [
      for (var slot = 0; slot < 4; slot++)
        alertMessage(firstName: 'Awa', reminder: nine, weekday: 1, slot: slot),
    ];
    for (final m in messages) {
      expect(RegExp(r'^[^\w\s]').hasMatch(m.title), isTrue, reason: m.title);
    }
    expect(messages.first.mood, 3); // bonne humeur le matin
    expect(messages.map((m) => m.mood).toSet().length, greaterThan(1));
    expect(
      eveningRescueMessage(firstName: 'Awa', streak: 3, remaining: 2).mood,
      0,
    );
  });
}
