import 'dart:ui' show Color;

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart';

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

/// Boutons des alertes.
const drankAction = 'drank';
const snoozeAction = 'snooze';
const snoozeDelay = Duration(minutes: 15);

/// Alertes riches (awesome_notifications) : grande image de Reno ou du
/// conseil du jour, boutons « J'ai bu ✓ » et « Plus tard » qui marchent
/// sans ouvrir l'appli.
class AwesomeReminderScheduler implements ReminderScheduler {
  AwesomeReminderScheduler({required this.onAction});

  /// Point d'entrée des boutons (fonction statique, appelée même quand
  /// l'appli est fermée).
  final ActionHandler onAction;

  final _notifications = AwesomeNotifications();

  static const channelKey = 'alertes_eau';
  static const _blue = Color(0xFF1CB0F6);
  static const _green = Color(0xFF58CC02);

  @override
  Future<void> init() async {
    await _notifications.initialize(
      'resource://drawable/ic_notification',
      [
        NotificationChannel(
          channelKey: channelKey,
          channelName: 'Alertes pour boire',
          channelDescription: 'Sonne aux heures où tu dois boire',
          importance: NotificationImportance.High,
          defaultColor: _blue,
          ledColor: _blue,
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 500, 250, 500]),
          defaultRingtoneType: DefaultRingtoneType.Notification,
        ),
      ],
      languageCode: 'fr',
    );
    await _notifications.setListeners(onActionReceivedMethod: onAction);
  }

  @override
  Future<bool> requestPermission() async {
    if (!await _notifications.isNotificationAllowed()) {
      await _notifications.requestPermissionToSendNotifications(
        channelKey: channelKey,
      );
    }
    // Heure exacte (Android 12+) : demandée une fois, sinon à quelques
    // minutes près.
    final precise = await _notifications.checkPermissionList(
      channelKey: channelKey,
      permissions: const [NotificationPermission.PreciseAlarms],
    );
    if (precise.isEmpty) {
      await _notifications.requestPermissionToSendNotifications(
        channelKey: channelKey,
        permissions: const [NotificationPermission.PreciseAlarms],
      );
    }
    return _notifications.isNotificationAllowed();
  }

  /// Une alerte par jour de la semaine et par heure (8 × 7 = 56 au plus,
  /// sous la limite de 64 alertes programmées d'iOS), pour varier les
  /// conseils et les images.
  @override
  Future<void> scheduleAll(HydrationPlan plan, UserProfile? profile) async {
    await _notifications.cancelAllSchedules();
    final timeZone = await _notifications.getLocalTimeZoneIdentifier();
    for (var weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++) {
      for (var i = 0; i < plan.reminders.length; i++) {
        final reminder = plan.reminders[i];
        await _notifications.createNotification(
          content: alertContent(
            id: weekday * 10000 + reminder.minutes,
            reminder: reminder,
            profile: profile,
            tip: kidneyTips[tipIndexFor(weekday, i)],
          ),
          actionButtons: alertButtons,
          schedule: NotificationCalendar(
            weekday: weekday,
            hour: reminder.hour,
            minute: reminder.minute,
            second: 0,
            millisecond: 0,
            repeats: true,
            allowWhileIdle: true,
            preciseAlarm: true,
            timeZone: timeZone,
          ),
        );
      }
    }
  }

  @override
  Future<void> showTest(Reminder reminder, UserProfile? profile) =>
      _notifications.createNotification(
        content: alertContent(
          id: 1,
          reminder: reminder,
          profile: profile,
          tip: kidneyTips[tipIndexFor(DateTime.now().weekday, 0)],
        ),
        actionButtons: alertButtons,
      );

  @override
  Future<void> cancelAll() => _notifications.cancelAll();

  /// Refait sonner la même alerte dans [snoozeDelay].
  static Future<void> snooze(ReceivedAction action) async {
    final minutes = action.payload?['minutes'];
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 900000 + (int.tryParse(minutes ?? '') ?? 0),
        channelKey: channelKey,
        title: action.title,
        body: action.body,
        bigPicture: action.bigPicture,
        largeIcon: action.largeIcon,
        notificationLayout: NotificationLayout.BigPicture,
        category: NotificationCategory.Reminder,
        color: _blue,
        wakeUpScreen: true,
        payload: action.payload,
      ),
      actionButtons: alertButtons,
      schedule: NotificationInterval(
        interval: snoozeDelay,
        allowWhileIdle: true,
        preciseAlarm: true,
      ),
    );
  }

  static List<NotificationActionButton> get alertButtons => [
        NotificationActionButton(
          key: drankAction,
          label: 'J\'ai bu ✓',
          color: _green,
          actionType: ActionType.SilentBackgroundAction,
        ),
        NotificationActionButton(
          key: snoozeAction,
          label: 'Plus tard (15 min)',
          actionType: ActionType.SilentBackgroundAction,
        ),
      ];

  static NotificationContent alertContent({
    required int id,
    required Reminder reminder,
    required UserProfile? profile,
    required KidneyTip tip,
  }) =>
      NotificationContent(
        id: id,
        channelKey: channelKey,
        title: alertTitle(profile),
        body: '${alertBody(reminder)}\n${tip.short}',
        summary: 'Alerte de ${reminder.time}',
        bigPicture: notificationImage(tip.asset),
        largeIcon: 'asset://assets/notif/reno_face.png',
        notificationLayout: NotificationLayout.BigPicture,
        category: NotificationCategory.Reminder,
        color: _blue,
        wakeUpScreen: true,
        payload: {'minutes': '${reminder.minutes}'},
      );
}

/// « assets/illustrations/kidney_stones.svg » → sa version PNG pour la
/// notification.
String notificationImage(String svgAsset) {
  final name = svgAsset.split('/').last.replaceAll('.svg', '');
  return 'asset://assets/notif/$name.png';
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
