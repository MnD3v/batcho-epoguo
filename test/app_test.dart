import 'package:bois_et_vis/data/hydration_store.dart';
import 'package:bois_et_vis/hydration_controller.dart';
import 'package:bois_et_vis/main.dart';
import 'package:bois_et_vis/models/drink.dart';
import 'package:bois_et_vis/services/reminder_scheduler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeScheduler implements ReminderScheduler {
  DrinkSettings? scheduled;
  int permissionRequests = 0;

  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return true;
  }

  @override
  Future<void> scheduleAll(DrinkSettings settings) async =>
      scheduled = settings;

  @override
  Future<void> showTest(DrinkSettings settings) async {}
}

void main() {
  late FakeScheduler scheduler;

  Future<HydrationController> controller(Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues(prefs);
    scheduler = FakeScheduler();
    return HydrationController(
      store: await HydrationStore.load(),
      scheduler: scheduler,
      clock: () => DateTime(2026, 9, 26, 10, 15),
    );
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
  }

  testWidgets('premier lancement : choix de la boisson puis accueil', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    addTearDown(tester.view.reset);
    final c = await controller({});
    await tester.pumpWidget(BoisEtVisApp(controller: c));
    await tester.pumpAndSettle();

    expect(find.text('Bienvenue sur Bois & Vis'), findsOneWidget);
    await tester.ensureVisible(find.text('Verre'));
    await tester.tap(find.text('Verre'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Plus'));
    await tester.tap(find.byTooltip('Plus'));
    await tester.pumpAndSettle();
    expect(find.text('À chaque rappel : 2 verres (0,5 L)'), findsOneWidget);

    await tester.ensureVisible(find.text('Commencer'));
    await tester.tap(find.text('Commencer'));
    await tester.pumpAndSettle();

    expect(scheduler.scheduled?.doseMl, 500);
    expect(scheduler.permissionRequests, 1);
    expect(find.text('Mes rappels d\'aujourd\'hui'), findsOneWidget);
    expect(find.text('0 L / 3,5 L'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('cocher un rappel ajoute la quantité bue', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    addTearDown(tester.view.reset);
    final c = await controller({
      'drink_type': 'pureWater',
      'drink_unit_ml': 500,
      'drink_units': 1,
    });
    await tester.pumpWidget(BoisEtVisApp(controller: c));
    await tester.pumpAndSettle();

    expect(find.text('Prochain rappel à 11:00'), findsOneWidget);
    final nine = find.widgetWithText(CheckboxListTile, '09:00');
    await tester.scrollUntilVisible(
      nine,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.descendant(
        of: nine,
        matching: find.textContaining('C\'est le moment'),
      ),
      findsOneWidget,
    );

    await tester.tap(nine);
    await tester.pumpAndSettle();
    expect(c.drunkMl, 500);
    expect(c.isChecked(9), isTrue);

    await tester.tap(nine);
    await tester.pumpAndSettle();
    expect(c.drunkMl, 0);
    await unmount(tester);
  });
}
