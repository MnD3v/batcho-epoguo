import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/kidney_tips.dart';
import '../models/plan.dart';
import '../models/profile.dart';

/// Programme les alertes d'hydratation.
abstract class ReminderScheduler {
  Future<void> init();

  /// Demande l'autorisation d'envoyer des alertes (et, sur Android,
  /// de sonner à l'heure exacte).
  Future<bool> requestPermission();

  /// Remplace toutes les alertes par celles de [plan].
  Future<void> scheduleAll(HydrationPlan plan, UserProfile? profile);

  /// Fait sonner tout de suite une alerte d'essai.
  Future<void> showTest(Reminder reminder, UserProfile? profile);

  /// Arrête toutes les alertes (déconnexion).
  Future<void> cancelAll();
}

class LocalNotificationScheduler implements ReminderScheduler {
  final _plugin = FlutterLocalNotificationsPlugin();

  // Nouveau canal : sur Android, l'importance d'un canal existant ne peut
  // plus être changée.
  static const _channelId = 'alertes_eau';
  static const _channelName = 'Alertes pour boire';

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

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
    final android = _android;
    if (android != null) {
      final granted = await android.requestNotificationsPermission() ?? false;
      if (await android.canScheduleExactNotifications() == false) {
        await android.requestExactAlarmsPermission();
      }
      return granted;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
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

  /// Une alerte par jour de la semaine et par heure (8 × 7 = 56 au plus,
  /// sous la limite de 64 alertes programmées d'iOS), pour varier les conseils.
  @override
  Future<void> scheduleAll(HydrationPlan plan, UserProfile? profile) async {
    await _plugin.cancelAll();
    // Heure exacte si Android l'autorise, sinon à quelques minutes près.
    final exact = await _android?.canScheduleExactNotifications() ?? true;
    for (var weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++) {
      for (var i = 0; i < plan.reminders.length; i++) {
        final reminder = plan.reminders[i];
        final tip = kidneyTips[tipIndexFor(weekday, i)];
        await _plugin.zonedSchedule(
          id: weekday * 10000 + reminder.minutes,
          title: alertTitle(profile),
          body: alertBody(reminder),
          scheduledDate: _nextInstance(weekday, reminder.minutes),
          notificationDetails: _details(reminder, tip),
          androidScheduleMode: exact
              ? AndroidScheduleMode.exactAllowWhileIdle
              : AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }
    }
  }

  @override
  Future<void> cancelAll() => _plugin.cancelAll();

  @override
  Future<void> showTest(Reminder reminder, UserProfile? profile) async {
    final tip = kidneyTips[tipIndexFor(DateTime.now().weekday, 0)];
    await _plugin.show(
      id: 0,
      title: alertTitle(profile),
      body: alertBody(reminder),
      notificationDetails: _details(reminder, tip),
    );
  }

  NotificationDetails _details(Reminder reminder, KidneyTip tip) =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Sonne aux heures où tu dois boire',
          importance: Importance.max,
          priority: Priority.max,
          category: AndroidNotificationCategory.alarm,
          // Sonne comme un réveil, même en mode discret des notifications.
          audioAttributesUsage: AudioAttributesUsage.alarm,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 600, 300, 600, 300, 600]),
          color: const Color(0xFF1CB0F6),
          styleInformation: BigTextStyleInformation(
            '${alertBody(reminder)}\n${tip.short}',
          ),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBanner: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.active,
        ),
      );

  tz.TZDateTime _nextInstance(int weekday, int minutes) {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime at(int year, int month, int day) =>
        tz.TZDateTime(tz.local, year, month, day, minutes ~/ 60, minutes % 60);
    var date = at(now.year, now.month, now.day);
    while (date.weekday != weekday || !date.isAfter(now)) {
      date = at(date.year, date.month, date.day + 1);
    }
    return date;
  }
}

/// « Awa, lève-toi et bois ton eau ! 💧 »
String alertTitle(UserProfile? profile) {
  final name = profile?.firstName;
  return name == null || name.isEmpty
      ? 'Lève-toi et bois ton eau ! 💧'
      : '$name, lève-toi et bois ton eau ! 💧';
}

String alertBody(Reminder reminder) =>
    'Bois ${formatLiters(reminder.ml)} maintenant. $kidneyPriceMessage';
