import 'dart:io' show Platform;
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
    scheduler: _BackgroundScheduler(),
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

/// Bouton « J'ai bu ✓ » du widget, et de la notification sur Android
/// (boisetvis://drank?minutes=540 : l'alerte de 9h).
@pragma('vm:entry-point')
Future<void> onWidgetAction(Uri? uri) async {
  if (uri?.host == HomeWidgetSync.drankUri.host) {
    await quickCheckInBackground(
      minutes: int.tryParse(uri?.queryParameters['minutes'] ?? ''),
    );
  }
}

/// Cocher en arrière-plan ne reprogramme que l'alerte du soir.
class _BackgroundScheduler implements ReminderScheduler {
  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> scheduleAll(plan, profile, {bool loud = false}) async {}

  @override
  Future<void> showTest(reminder, profile, {bool loud = false}) async {}

  @override
  Future<void> scheduleEveningRescue(at, message) async {
    if (!Platform.isAndroid) {
      return AwesomeReminderScheduler.eveningRescue(at, message);
    }
    // Android : l'alarme native ne peut pas être annulée d'ici ; on note le
    // jour et l'alerte du soir ne s'affichera pas (AlertReceiver.kt).
    if (at == null) {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      await prefs.setString(
        'rescue_off_day',
        '${now.year}-${now.month.toString().padLeft(2, '0')}-'
            '${now.day.toString().padLeft(2, '0')}',
      );
    }
  }

  @override
  Future<void> cancelAll() async {}
}
