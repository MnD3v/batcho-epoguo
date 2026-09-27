import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/kidney_tips.dart';
import '../data/reminders.dart';
import '../models/drink.dart';

/// Programme les rappels d'hydratation.
abstract class ReminderScheduler {
  Future<void> init();

  /// Demande l'autorisation d'envoyer des notifications.
  Future<bool> requestPermission();

  /// Remplace tous les rappels par ceux de [settings].
  Future<void> scheduleAll(DrinkSettings settings);

  /// Envoie tout de suite une notification d'essai.
  Future<void> showTest(DrinkSettings settings);
}

class LocalNotificationScheduler implements ReminderScheduler {
  final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'rappels_eau';
  static const _channelName = 'Rappels pour boire';
  static const _title = 'C\'est l\'heure de boire 💧';

  @override
  Future<void> init() async {
    tzdata.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (e) {
      debugPrint('Fuseau horaire inconnu, UTC utilisé : $e');
      tz.setLocalLocation(tz.UTC);
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
  }

  @override
  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return false;
  }

  /// Un rappel par jour de la semaine et par créneau (7 × 7 = 49, sous la
  /// limite de 64 notifications programmées d'iOS), pour varier les conseils.
  @override
  Future<void> scheduleAll(DrinkSettings settings) async {
    await _plugin.cancelAll();
    for (var weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++) {
      for (var slot = 0; slot < reminderHours.length; slot++) {
        final tip = kidneyTips[tipIndexFor(weekday, slot)];
        final body = _body(settings, tip);
        await _plugin.zonedSchedule(
          id: weekday * 100 + reminderHours[slot],
          title: _title,
          body: body,
          scheduledDate: _nextInstance(weekday, reminderHours[slot]),
          notificationDetails: _details(body),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }
    }
  }

  @override
  Future<void> showTest(DrinkSettings settings) async {
    final now = DateTime.now();
    final tip =
        kidneyTips[tipIndexFor(now.weekday, currentSlotIndex(now) ?? 0)];
    final body = _body(settings, tip);
    await _plugin.show(
      id: 0,
      title: _title,
      body: body,
      notificationDetails: _details(body),
    );
  }

  String _body(DrinkSettings settings, KidneyTip tip) =>
      'Bois ${settings.doseLabel}. ${tip.short}';

  NotificationDetails _details(String body) => NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Rappels toutes les 2 heures, de 7h à 20h',
      importance: Importance.high,
      priority: Priority.high,
      color: const Color(0xFF0288D1),
      styleInformation: BigTextStyleInformation(body),
    ),
    iOS: const DarwinNotificationDetails(),
  );

  tz.TZDateTime _nextInstance(int weekday, int hour) {
    final now = tz.TZDateTime.now(tz.local);
    var date = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);
    while (date.weekday != weekday || !date.isAfter(now)) {
      date = tz.TZDateTime(tz.local, date.year, date.month, date.day + 1, hour);
    }
    return date;
  }
}
