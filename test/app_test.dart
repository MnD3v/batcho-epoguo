import 'package:bois_et_vis/data/hydration_store.dart';
import 'package:bois_et_vis/hydration_controller.dart';
import 'package:bois_et_vis/main.dart';
import 'package:bois_et_vis/models/plan.dart';
import 'package:bois_et_vis/models/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

void main() {
  late FakeScheduler scheduler;

  Future<HydrationController> start(
    WidgetTester tester,
    Map<String, Object> prefs,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues(prefs);
    scheduler = FakeScheduler();
    final c = HydrationController(
      store: await HydrationStore.load(),
      scheduler: scheduler,
      clock: () => DateTime(2026, 9, 27, 10, 15),
    );
    await tester.pumpWidget(BoisEtVisApp(controller: c));
    await tester.pumpAndSettle();
    return c;
  }

  /// Fait défiler jusqu'à [finder] (les listes ne construisent que ce qui
  /// est proche de l'écran), le centre, puis le touche.
  Future<void> tap(WidgetTester tester, Finder finder) async {
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        finder,
        200,
        scrollable: find.byType(Scrollable).first,
      );
    }
    finder = finder.last;
    await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Finder text(String s) => find.text(s);

  testWidgets('premier lancement : questions puis alertes à heures précises', (
    tester,
  ) async {
    final c = await start(tester, {});
    expect(find.textContaining('Moi, c\'est Reno'), findsOneWidget);
    await tap(tester, text('C\'EST PARTI'));

    // Prénom et e-mail obligatoires.
    await tester.enterText(find.byType(TextField).at(0), 'Awa');
    await tester.enterText(find.byType(TextField).at(1), 'awa@exemple');
    await tester.pumpAndSettle();
    expect(find.text('Adresse e-mail invalide'), findsOneWidget);
    await tap(tester, text('CONTINUER'));
    expect(find.byType(TextField), findsNWidgets(2)); // toujours bloqué
    await tester.enterText(find.byType(TextField).at(1), 'awa@exemple.com');
    await tester.pumpAndSettle();
    await tap(tester, text('CONTINUER'));

    expect(find.textContaining('Enchanté, Awa !'), findsOneWidget);
    await tap(tester, text('Environ 2 L'));
    await tap(tester, text('CONTINUER'));

    await tap(tester, text('J\'oublie de boire'));
    await tap(tester, text('Pas d\'eau à côté de moi'));
    await tap(tester, text('CONTINUER'));
    expect(c.profile?.difficulties, {
      Difficulty.forget,
      Difficulty.noWaterNearby,
    });

    await tap(tester, text('À des heures précises'));
    await tap(tester, text('CONTINUER'));

    // Exemple proposé : 9h, 12h, 15h, 18h à 0,5 L.
    for (final t in ['09:00', '12:00', '15:00', '18:00']) {
      expect(find.text(t), findsOneWidget);
    }
    await tap(tester, find.byTooltip('Plus').first); // 9h → 0,75 L
    await tap(tester, find.byTooltip('Supprimer').at(1)); // retire 12h
    await tap(tester, text('AJOUTER UNE HEURE')); // 20h
    expect(find.text('2,25 L en 4 alertes'), findsOneWidget);
    await tap(tester, text('CONTINUER'));

    expect(find.textContaining('Tout est prêt, Awa !'), findsOneWidget);
    expect(
        find.textContaining('Awa, lève-toi et bois ton eau'), findsOneWidget);
    expect(find.textContaining('15 000 000 FCFA'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('Garde une bouteille'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tap(tester, text('ACTIVER MES ALERTES'));

    expect(scheduler.permissionRequests, 1);
    expect(scheduler.scheduledFor?.firstName, 'Awa');
    expect(scheduler.scheduled?.reminders, const [
      Reminder(9 * 60, 750),
      Reminder(15 * 60, 500),
      Reminder(18 * 60, 500),
      Reminder(20 * 60, 500),
    ]);
    expect(find.text('0 L sur 2,25 L'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('le parcours : cocher, gagner des XP, étapes verrouillées', (
    tester,
  ) async {
    final c = await start(tester, setUpPrefs);
    expect(find.textContaining('Awa, lève-toi et bois 0,25 L'), findsOneWidget);

    final nine = find.byKey(const ValueKey('slot_09:00'));
    await tap(tester, nine);
    expect(find.text('+10 XP'), findsOneWidget);
    await tap(tester, text('CONTINUER'));
    expect(find.text('Nouveau badge !'), findsOneWidget);
    await tap(tester, text('CONTINUER'));
    expect(c.xp, 10);

    await tap(tester, find.byKey(const ValueKey('slot_11:00')));
    expect(find.text('Cette alerte s\'ouvre à 11:00 🔒'), findsOneWidget);

    await tap(tester, nine);
    await tap(tester, text('DÉCOCHER'));
    expect(c.xp, 0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('profil : modifier ses alertes', (tester) async {
    await start(tester, setUpPrefs);
    await tester.tap(find.bySemanticsLabel('Profil'));
    await tester.pumpAndSettle();
    expect(find.text('Awa'), findsOneWidget);
    expect(find.text('awa@exemple.com'), findsOneWidget);

    await tap(tester, text('MODIFIER MES ALERTES'));
    await tap(tester, text('Toutes les 3 heures'));
    await tap(tester, text('CONTINUER'));
    await tap(tester, text('0,5 L'));
    await tap(tester, text('CONTINUER'));
    await tap(tester, text('ENREGISTRER'));

    expect(scheduler.scheduled?.reminders.map((r) => r.time), [
      '07:00',
      '10:00',
      '13:00',
      '16:00',
      '19:00',
    ]);
    expect(find.text('Toutes les 3 heures · 2,5 L par jour'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('leçons et succès', (tester) async {
    final c = await start(tester, setUpPrefs);
    await tester.tap(find.bySemanticsLabel('Leçons'));
    await tester.pumpAndSettle();
    await tap(tester, text('Calculs rénaux'));
    await tap(tester, text('J\'AI COMPRIS'));
    expect(find.text('+5 XP'), findsOneWidget);
    await tap(tester, text('CONTINUER'));
    expect(c.isTipRead(1), isTrue);

    await tester.tap(find.bySemanticsLabel('Succès'));
    await tester.pumpAndSettle();
    expect(find.text('Niveau 1 · Goutte'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
