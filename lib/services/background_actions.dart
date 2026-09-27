import 'dart:ui' show DartPluginRegistrant;

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/hydration_store.dart';
import '../hydration_controller.dart';
import 'home_widget_sync.dart';
import 'reminder_scheduler.dart';

/// Coche une alerte sans ouvrir l'appli (bouton de notification ou du
/// widget). Tourne dans un isolate à part : l'appli relit les données à son
/// retour au premier plan.
Future<void> quickCheckInBackground({int? minutes}) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  await prefs.reload();
  final controller = HydrationController(
    store: HydrationStore(prefs),
    scheduler: _NoScheduler(),
  );
  await controller.quickCheck(minutes: minutes);
  await HomeWidgetSync.push(controller);
}

/// Boutons des alertes (appelé même quand l'appli est fermée).
@pragma('vm:entry-point')
Future<void> onNotificationAction(ReceivedAction action) async {
  switch (action.buttonKeyPressed) {
    case drankAction:
      await quickCheckInBackground(
        minutes: int.tryParse(action.payload?['minutes'] ?? ''),
      );
    case snoozeAction:
      await AwesomeReminderScheduler.snooze(action);
  }
}

/// Bouton « J'ai bu ✓ » du widget.
@pragma('vm:entry-point')
Future<void> onWidgetAction(Uri? uri) async {
  if (uri?.host == HomeWidgetSync.drankUri.host) {
    await quickCheckInBackground();
  }
}

/// Cocher n'a pas besoin de reprogrammer les alertes.
class _NoScheduler implements ReminderScheduler {
  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> scheduleAll(plan, profile) async {}

  @override
  Future<void> showTest(reminder, profile) async {}

  @override
  Future<void> cancelAll() async {}
}
