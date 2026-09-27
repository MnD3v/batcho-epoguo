import 'dart:ui' show Color;

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart';

import '../data/alert_messages.dart';
import '../data/kidney_tips.dart';
import '../models/plan.dart';
import '../models/profile.dart';

/// Programme les alertes d'hydratation.
abstract class ReminderScheduler {
  Future<void> init();

  /// Demande l'autorisation d'envoyer des alertes (et, sur Android,
  /// de sonner à l'heure exacte).
  Future<bool> requestPermission();

  /// Remplace toutes les alertes par celles de [plan]. [loud] : sonnerie de
  /// réveil au lieu du son de notification.
  Future<void> scheduleAll(
    HydrationPlan plan,
    UserProfile? profile, {
    bool loud = false,
  });

  /// Fait sonner tout de suite une alerte d'essai.
  Future<void> showTest(
    Reminder reminder,
    UserProfile? profile, {
    bool loud = false,
  });

  /// Alerte unique du soir quand la flamme est en danger (remplace la
  /// précédente) ; [at] null l'annule.
  Future<void> scheduleEveningRescue(DateTime? at, AlertMessage? message);

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

  /// Son de notification (par défaut) ou sonnerie de réveil.
  static const channelKey = 'alertes_eau';
  static const loudChannelKey = 'alertes_eau_fortes';
  static const _eveningId = 800000;
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
          channelDescription: 'Son doux aux heures où tu dois boire',
          importance: NotificationImportance.High,
          defaultColor: _blue,
          ledColor: _blue,
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 400, 200, 400]),
          defaultRingtoneType: DefaultRingtoneType.Notification,
        ),
        NotificationChannel(
          channelKey: loudChannelKey,
          channelName: 'Alertes fortes (réveil)',
          channelDescription:
              'Sonne comme un réveil aux heures où tu dois boire',
          importance: NotificationImportance.Max,
          defaultColor: _blue,
          ledColor: _blue,
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 600, 300, 600, 300, 600]),
          defaultRingtoneType: DefaultRingtoneType.Alarm,
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
  Future<void> scheduleAll(
    HydrationPlan plan,
    UserProfile? profile, {
    bool loud = false,
  }) async {
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
            weekday: weekday,
            slot: i,
            loud: loud,
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
  Future<void> showTest(
    Reminder reminder,
    UserProfile? profile, {
    bool loud = false,
  }) =>
      _notifications.createNotification(
        content: alertContent(
          id: 1,
          reminder: reminder,
          profile: profile,
          weekday: DateTime.now().weekday,
          slot: 0,
          loud: loud,
        ),
        actionButtons: alertButtons,
      );

  @override
  Future<void> scheduleEveningRescue(DateTime? at, AlertMessage? message) =>
      eveningRescue(at, message);

  /// Aussi appelé depuis l'arrière-plan, après « J'ai bu ✓ ».
  static Future<void> eveningRescue(
    DateTime? at,
    AlertMessage? message,
  ) async {
    final notifications = AwesomeNotifications();
    await notifications.cancel(_eveningId);
    if (at == null || message == null) return;
    await notifications.createNotification(
      content: NotificationContent(
        id: _eveningId,
        channelKey: channelKey,
        title: message.title,
        body: message.body,
        bigPicture: 'asset://assets/notif/mascot_sad.png',
        largeIcon: 'asset://assets/notif/reno_face.png',
        notificationLayout: NotificationLayout.BigPicture,
        category: NotificationCategory.Reminder,
        color: _blue,
      ),
      schedule: NotificationCalendar.fromDate(
        date: at,
        allowWhileIdle: true,
        preciseAlarm: true,
      ),
    );
  }

  @override
  Future<void> cancelAll() => _notifications.cancelAll();

  /// Refait sonner la même alerte dans [snoozeDelay].
  static Future<void> snooze(ReceivedAction action) async {
    final minutes = action.payload?['minutes'];
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 900000 + (int.tryParse(minutes ?? '') ?? 0),
        channelKey: action.channelKey ?? channelKey,
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
    required int weekday,
    required int slot,
    bool loud = false,
  }) {
    final tip = kidneyTips[tipIndexFor(weekday, slot)];
    final message = alertMessage(
      firstName: profile?.firstName,
      reminder: reminder,
      weekday: weekday,
      slot: slot,
    );
    return NotificationContent(
      id: id,
      channelKey: loud ? loudChannelKey : channelKey,
      title: message.title,
      body: '${message.body}\n${tip.short}',
      summary: 'Alerte de ${reminder.time}',
      bigPicture: notificationImage(tip.asset),
      largeIcon: 'asset://assets/notif/reno_face.png',
      notificationLayout: NotificationLayout.BigPicture,
      category:
          loud ? NotificationCategory.Alarm : NotificationCategory.Reminder,
      color: _blue,
      wakeUpScreen: true,
      payload: {'minutes': '${reminder.minutes}'},
    );
  }
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
