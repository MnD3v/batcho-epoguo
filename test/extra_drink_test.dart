import 'package:bois_et_vis/data/hydration_store.dart';
import 'package:bois_et_vis/hydration_controller.dart';
import 'package:bois_et_vis/models/game.dart';
import 'package:bois_et_vis/models/plan.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

void main() {
  Future<HydrationController> make() async {
    SharedPreferences.setMockInitialValues(setUpPrefs);
    return HydrationController(
      store: await HydrationStore.load(),
      scheduler: FakeScheduler(),
      clock: () => DateTime(2026, 9, 27, 10, 40),
    );
  }

  test('boire à tout moment compte dans le total, sans cocher d\'alerte',
      () async {
    final c = await make();
    final reward = await c.drinkExtra(500);
    expect(reward.xp, xpPerExtraDrink);
    expect(c.drunkMl, 500);
    expect(c.checkedCount, 0);
    expect(c.extras.single, const ExtraDrink(10 * 60 + 40, 500));
    expect(c.stats.totalMl, 500);
    // Compte aussi dans les courbes et les défis.
    expect(c.lastDays(1).single.liters, 0.5);
    expect(c.weekMl, 500);
    // Sauvegardé.
    final store = await HydrationStore.load();
    expect(store.extras(DateTime(2026, 9, 27)).length, 1);
  });

  test('XP limités à 4 verres par jour ; annuler retire les XP', () async {
    final c = await make();
    for (var i = 0; i < 5; i++) {
      await c.drinkExtra(250);
    }
    expect(c.xp, maxExtraDrinksWithXp * xpPerExtraDrink);
    expect(c.drunkMl, 1250);

    // Retirer un verre quand il y en a 5 ne change pas les XP (4 comptent).
    await c.removeExtra(c.extras.last);
    expect(c.xp, 20);
    await c.removeExtra(c.extras.first);
    expect(c.xp, 15);
    expect(c.drunkMl, 750);
    expect(c.stats.totalMl, 750);
  });

  test('la flamme reste liée aux alertes', () async {
    final c = await make();
    for (var i = 0; i < 6; i++) {
      await c.drinkExtra(500);
    }
    expect(c.streakSafeToday, isFalse);
    expect(c.goalReached, isFalse);
  });
}
