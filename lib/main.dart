import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/hydration_store.dart';
import 'hydration_controller.dart';
import 'screens/main_shell.dart';
import 'screens/onboarding_screen.dart';
import 'services/reminder_scheduler.dart';
import 'theme/duo.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await HydrationStore.load();
  final scheduler = LocalNotificationScheduler();
  await scheduler.init();
  final controller = HydrationController(store: store, scheduler: scheduler);
  // Reprogramme à chaque lancement : utile si le fuseau horaire a changé.
  final settings = controller.settings;
  if (settings != null) scheduler.scheduleAll(settings);
  runApp(BoisEtVisApp(controller: controller));
}

class BoisEtVisApp extends StatelessWidget {
  const BoisEtVisApp({super.key, required this.controller});

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
      home: controller.settings == null
          ? OnboardingScreen(controller: controller, isFirstRun: true)
          : MainShell(controller: controller),
    );
  }
}
