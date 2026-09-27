import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_root.dart';
import 'data/hydration_store.dart';
import 'firebase_options.dart';
import 'hydration_controller.dart';
import 'services/auth_service.dart';
import 'services/background_actions.dart';
import 'services/demo_auth_service.dart';
import 'services/firebase_auth_service.dart';
import 'services/home_widget_sync.dart';
import 'services/reminder_scheduler.dart';
import 'services/user_repository.dart';
import 'theme/duo.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final store = HydrationStore(prefs);
  final scheduler = AwesomeReminderScheduler(onAction: onNotificationAction);
  await scheduler.init();

  // Firebase si les clés sont là (`flutterfire configure`), sinon mode démo.
  AuthService auth;
  UserRepository cloud;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    auth = FirebaseAuthService();
    cloud = FirestoreUserRepository();
  } catch (e) {
    debugPrint('Mode démo : $e');
    auth = DemoAuthService(prefs);
    cloud = DemoUserRepository(prefs);
  }

  final controller = HydrationController(
    store: store,
    scheduler: scheduler,
    cloud: cloud,
  );
  // Le widget suit chaque changement ; son bouton coche en arrière-plan.
  controller.addListener(() => HomeWidgetSync.push(controller));
  HomeWidgetSync.push(controller);
  try {
    await HomeWidget.registerInteractivityCallback(onWidgetAction);
  } catch (e) {
    debugPrint('Widget indisponible : $e');
  }
  // Reprogramme à chaque lancement : utile si le fuseau horaire a changé.
  if (auth.user.value != null) {
    await controller.protectStreak();
    controller.rescheduleAlerts();
  }
  runApp(BoisEtVisApp(auth: auth, controller: controller));
}

class BoisEtVisApp extends StatelessWidget {
  const BoisEtVisApp({super.key, required this.auth, required this.controller});

  final AuthService auth;
  final HydrationController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bois & Vis',
      debugShowCheckedModeBanner: false,
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: Duo.theme(),
      home: AppRoot(auth: auth, controller: controller),
    );
  }
}
