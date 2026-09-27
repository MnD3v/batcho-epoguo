import 'package:bois_et_vis/data/hydration_store.dart';
import 'package:bois_et_vis/data/kidney_tips.dart';
import 'package:bois_et_vis/data/reminders.dart';
import 'package:bois_et_vis/models/drink.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('formatLiters', () {
    expect(formatLiters(500), '0,5 L');
    expect(formatLiters(1750), '1,75 L');
    expect(formatLiters(3500), '3,5 L');
    expect(formatLiters(2000), '2 L');
    expect(formatLiters(0), '0 L');
  });

  test('libellés de dose', () {
    expect(
      DrinkSettings.defaults(DrinkType.pureWater).doseLabel,
      '1 pure water (0,5 L)',
    );
    expect(
      const DrinkSettings(
        type: DrinkType.glass,
        unitMl: 250,
        unitsPerReminder: 2,
      ).doseLabel,
      '2 verres (0,5 L)',
    );
  });

  test('rappels de 7h à 20h toutes les 2 heures', () {
    expect(reminderHours, [7, 9, 11, 13, 15, 17, 19]);
    DateTime at(int h, [int m = 0]) => DateTime(2026, 9, 26, h, m);
    expect(currentSlotIndex(at(6, 59)), isNull);
    expect(currentSlotIndex(at(7)), 0);
    expect(currentSlotIndex(at(8, 59)), 0);
    expect(currentSlotIndex(at(19, 30)), 6);
    expect(currentSlotIndex(at(21)), isNull);
    expect(nextSlotIndex(at(6)), 0);
    expect(nextSlotIndex(at(9, 30)), 2);
    expect(nextSlotIndex(at(19)), isNull);
  });

  test('chaque conseil est utilisé dans la semaine', () {
    final used = {
      for (var d = 1; d <= 7; d++)
        for (var s = 0; s < reminderHours.length; s++) tipIndexFor(d, s),
    };
    expect(used.length, kidneyTips.length);
  });

  test('le stockage garde la boisson et les rappels cochés par jour', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await HydrationStore.load();
    expect(store.settings, isNull);

    await store.saveSettings(
      const DrinkSettings(
        type: DrinkType.glass,
        unitMl: 300,
        unitsPerReminder: 2,
      ),
    );
    final saved = store.settings!;
    expect(saved.type, DrinkType.glass);
    expect(saved.doseMl, 600);

    final day = DateTime(2026, 9, 26);
    await store.saveChecks(day, {7: 600, 9: 500});
    expect(store.checks(day), {7: 600, 9: 500});
    expect(store.checks(DateTime(2026, 9, 27)), isEmpty);

    // Les jours trop anciens sont supprimés.
    await store.saveChecks(DateTime(2026, 12, 31), {7: 500});
    expect(store.checks(day), isEmpty);
  });
}
