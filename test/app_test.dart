import 'dart:convert';

import 'package:bois_et_vis/data/hydration_store.dart';
import 'package:bois_et_vis/hydration_controller.dart';
import 'package:bois_et_vis/main.dart';
import 'package:bois_et_vis/models/plan.dart';
import 'package:bois_et_vis/models/profile.dart';
import 'package:bois_et_vis/services/demo_auth_service.dart';
import 'package:bois_et_vis/services/social_repository.dart';
import 'package:bois_et_vis/services/user_repository.dart';
import 'package:bois_et_vis/social_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

void main() {
  late FakeScheduler scheduler;
  late SharedPreferences prefs;

  Future<HydrationController> start(
    WidgetTester tester,
    Map<String, Object> initial,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues(initial);
    prefs = await SharedPreferences.getInstance();
    scheduler = FakeScheduler();
    final c = HydrationController(
      store: HydrationStore(prefs),
      scheduler: scheduler,
      cloud: DemoUserRepository(prefs),
      clock: () => DateTime(2026, 9, 27, 10, 15),
    );
    await tester.pumpWidget(
      BoisEtVisApp(
        auth: DemoAuthService(prefs),
        controller: c,
        social: SocialController(
          repository: DemoSocialRepository(prefs),
          hydration: c,
          store: HydrationStore(prefs),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return c;
  }

  /// Fait défiler jusqu'à [finder] (les listes ne construisent que ce qui
  /// est proche de l'écran), le centre, puis le touche.
  Future<void> tap(WidgetTester tester, Finder finder) async {
    if (finder.evaluate().isEmpty) {
      // Remonte en haut de la liste, puis descend jusqu'à le trouver.
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 5000));
      await tester.pumpAndSettle();
    }
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

  Future<void> type(WidgetTester tester, String label, String value) async {
    await tester.enterText(find.widgetWithText(TextField, label), value);
    await tester.pumpAndSettle();
  }

  Map<String, dynamic>? cloudDoc(String uid) {
    final raw = prefs.getString('demo_cloud_$uid');
    return raw == null ? null : jsonDecode(raw) as Map<String, dynamic>;
  }

  testWidgets(
      'sans compte : questionnaire, première gorgée, puis compte qui garde '
      'la progression', (tester) async {
    final c = await start(tester, {});
    expect(find.text('Bois & Vis'), findsOneWidget);
    expect(find.textContaining('Mode démo'), findsOneWidget);
    await tap(tester, text('COMMENCER'));

    // Le prénom d'abord, sans compte.
    expect(find.textContaining('comment tu t\'appelles'), findsOneWidget);
    await type(tester, 'Prénom', 'Awa');
    await tap(tester, text('CONTINUER'));

    expect(find.textContaining('Bienvenue, Awa !'), findsOneWidget);
    await tap(tester, text('Environ 2 L'));
    await tap(tester, text('CONTINUER'));

    await tap(tester, text('J\'oublie de boire'));
    await tap(tester, text('Pas d\'eau à côté de moi'));
    await tap(tester, text('CONTINUER'));

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
    expect(find.textContaining('15 000 000 FCFA'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('Garde une bouteille'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tap(tester, text('ACTIVER MES ALERTES'));

    expect(scheduler.scheduledFor?.firstName, 'Awa');
    expect(scheduler.scheduled?.reminders, const [
      Reminder(9 * 60, 750),
      Reminder(15 * 60, 500),
      Reminder(18 * 60, 500),
      Reminder(20 * 60, 500),
    ]);
    expect(find.text('0 L sur 2,25 L'), findsOneWidget);
    expect(c.uid, isNull);

    // Première gorgée : +10 XP, badge, puis Reno propose le compte.
    await tap(tester, find.byKey(const ValueKey('slot_09:00')));
    await tap(tester, text('CONTINUER'));
    await tap(tester, text('CONTINUER'));
    expect(
      find.textContaining('Crée ton compte pour ne pas perdre tes 10 XP'),
      findsOneWidget,
    );
    await tap(tester, text('CRÉER MON COMPTE'));

    // Prénom déjà rempli ; le bouton reste gris tant que ce n'est pas valide.
    expect(find.text('Awa'), findsOneWidget);
    await type(tester, 'E-mail', 'awa@exemple');
    await type(tester, 'Mot de passe', '123');
    expect(find.text('Adresse e-mail invalide'), findsOneWidget);
    expect(find.text('Trop court : 6 caractères minimum'), findsOneWidget);
    await type(tester, 'E-mail', 'awa@exemple.com');
    await type(tester, 'Mot de passe', 'secret1');
    await tap(tester, text('CRÉER MON COMPTE'));

    // La progression est gardée et sauvegardée « en ligne ».
    expect(find.text('0,75 L sur 2,25 L'), findsOneWidget);
    expect(c.xp, 10);
    expect(c.profile?.email, 'awa@exemple.com');
    await tester.pumpAndSettle();
    final uid = prefs.getString('demo_current_uid')!;
    final doc = cloudDoc(uid)!;
    expect(doc['firstName'], 'Awa');
    expect(doc['email'], 'awa@exemple.com');
    expect(doc['usualIntake'], 'Environ 2 L');
    expect(doc['difficulties'], contains('J\'oublie de boire'));
    expect(doc['dailyGoalMl'], 2250);
    expect(doc['xp'], 10);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('sans compte : les amis demandent un compte', (tester) async {
    await start(tester, setUpPrefs);
    await tester.tap(find.bySemanticsLabel('Amis'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Crée ton compte pour défier tes amis'),
        findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('connexion : erreur, puis progression retrouvée', (
    tester,
  ) async {
    final c = await start(tester, {
      ...awaAccount,
      'demo_cloud_$awaUid': jsonEncode({
        'data': {...setUpPrefs, 'stats_checks': 12},
      }),
    });
    await tap(tester, text('J\'AI DÉJÀ UN COMPTE'));
    await type(tester, 'E-mail', 'awa@exemple.com');
    await type(tester, 'Mot de passe', 'mauvais');
    await tap(tester, text('SE CONNECTER'));
    expect(find.text('E-mail ou mot de passe incorrect.'), findsOneWidget);

    await type(tester, 'Mot de passe', 'secret1');
    await tap(tester, text('SE CONNECTER'));
    expect(find.textContaining('Awa, lève-toi et bois 0,25 L'), findsOneWidget);
    expect(c.xp, 120);
    expect(scheduler.scheduled?.reminders.length, 7);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('mot de passe oublié', (tester) async {
    await start(tester, awaAccount);
    await tap(tester, text('J\'AI DÉJÀ UN COMPTE'));
    await type(tester, 'E-mail', 'awa@exemple.com');
    await tap(tester, text('Mot de passe oublié ?'));
    await tap(tester, text('ENVOYER LE LIEN'));
    expect(find.textContaining('aucun e-mail'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('le parcours : cocher, gagner des XP, étapes verrouillées', (
    tester,
  ) async {
    final c = await start(tester, signedInPrefs);
    expect(find.textContaining('Awa, lève-toi et bois 0,25 L'), findsOneWidget);

    final nine = find.byKey(const ValueKey('slot_09:00'));
    await tap(tester, nine);
    expect(find.text('+10 XP'), findsOneWidget);
    await tap(tester, text('CONTINUER'));
    expect(find.text('Nouveau badge !'), findsOneWidget);
    await tap(tester, text('CONTINUER'));
    expect(c.xp, 10);

    await tap(tester, find.byKey(const ValueKey('slot_11:00')));
    expect(find.textContaining('Cette alerte s\'ouvre à 11:00 🔒'),
        findsOneWidget);
    expect(find.textContaining('« + J\'ai bu »'), findsWidgets);

    // Boire à tout moment : « + J'ai bu », puis un pure water.
    await tap(tester, text('+ J\'AI BU'));
    await tap(tester, text('Un pure water'));
    expect(find.text('+5 XP'), findsOneWidget);
    await tap(tester, text('CONTINUER'));
    expect(c.drunkMl, 750);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 5000));
    await tester.pumpAndSettle();
    expect(find.text('0,75 L sur 1,75 L'), findsOneWidget);
    // Annuler ce verre (erreur de doigt).
    await tap(tester, find.byTooltip('Annuler'));
    expect(c.drunkMl, 250);

    await tap(tester, nine);
    await tap(tester, text('DÉCOCHER'));
    expect(c.xp, 0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('paramètres : prénom, alertes, déconnexion', (tester) async {
    final c = await start(tester, signedInPrefs);
    await tester.tap(find.bySemanticsLabel('Profil'));
    await tester.pumpAndSettle();
    expect(find.text('awa@exemple.com'), findsOneWidget);

    await tap(tester, text('ANNÉE'));
    expect(find.text('Moyenne par jour, sur 12 mois'), findsOneWidget);

    // Retour en haut du profil, où se trouve la roue dentée.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
    await tester.pumpAndSettle();
    await tap(tester, find.byTooltip('Paramètres'));
    expect(find.text('Paramètres'), findsOneWidget);

    await tap(tester, text('Prénom'));
    await tester.enterText(find.widgetWithText(TextField, 'Prénom'), 'Awa K.');
    await tester.pumpAndSettle();
    await tap(tester, text('ENREGISTRER'));
    expect(c.profile?.firstName, 'Awa K.');
    expect(scheduler.scheduledFor?.firstName, 'Awa K.');

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

    await tap(tester, text('SE DÉCONNECTER'));
    await tap(tester, text('SE DÉCONNECTER'));
    expect(find.text('COMMENCER'), findsOneWidget);
    expect(scheduler.cancelled, greaterThan(0));
    expect(c.profile, isNull);
    // La progression reste en ligne pour la prochaine connexion.
    expect(cloudDoc(awaUid)?['rhythm'], 'Toutes les 3 heures');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('supprimer son compte', (tester) async {
    await start(tester, signedInPrefs);
    await tester.tap(find.bySemanticsLabel('Profil'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Paramètres'));
    await tester.pumpAndSettle();

    await tap(tester, text('SUPPRIMER MON COMPTE'));
    await type(tester, 'Ton mot de passe, pour confirmer', 'faux');
    await tap(tester, text('SUPPRIMER DÉFINITIVEMENT'));
    expect(find.text('Mot de passe incorrect.'), findsOneWidget);

    await type(tester, 'Ton mot de passe, pour confirmer', 'secret1');
    await tap(tester, text('SUPPRIMER DÉFINITIVEMENT'));
    expect(find.text('COMMENCER'), findsOneWidget);
    expect(cloudDoc(awaUid), isNull);
    expect(prefs.getString('demo_accounts'), isNot(contains('awa@')));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('amis : code d\'invitation et défi de la semaine', (
    tester,
  ) async {
    final c = await start(tester, signedInPrefs);
    await tap(tester, find.byKey(const ValueKey('slot_09:00')));
    await tap(tester, text('CONTINUER'));
    await tap(tester, text('CONTINUER'));

    await tester.tap(find.bySemanticsLabel('Amis'));
    await tester.pumpAndSettle();
    expect(find.text('Défie tes amis : qui boit le plus cette semaine ?'),
        findsOneWidget);
    // Un code d'invitation de 6 caractères a été créé.
    expect(prefs.getString('social_referral_code')?.length, 6);

    await tap(tester, text('CRÉER UN DÉFI'));
    await tester.enterText(find.byType(TextField).last, 'Famille');
    await tester.pumpAndSettle();
    await tap(tester, text('CRÉER'));
    expect(find.text('Famille'), findsOneWidget);
    expect(find.text('Awa (toi)'), findsOneWidget);
    expect(find.text('0,25 L'), findsWidgets);

    // Code inconnu : erreur dans la fenêtre, qui reste ouverte.
    await tap(tester, text('REJOINDRE AVEC UN CODE'));
    await tester.enterText(find.byType(TextField).last, 'ZZZZZZ');
    await tester.pumpAndSettle();
    await tap(tester, text('REJOINDRE'));
    expect(find.text('Ce défi n\'existe pas.'), findsOneWidget);
    expect(c.xp, 10);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('leçons et succès', (tester) async {
    final c = await start(tester, signedInPrefs);
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
    expect(c.profile?.difficulties, {Difficulty.forget});
    await tester.pumpWidget(const SizedBox());
  });
}
