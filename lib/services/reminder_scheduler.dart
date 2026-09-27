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

  /// Son doux (par défaut) ou sonnerie de réveil. Android fige le son et
  /// la vibration d'un canal : on change de clé quand ils changent.
  static const channelKey = 'alertes_eau_v2';
  static const loudChannelKey = 'alertes_eau_fortes_v2';
  static const _oldChannelKeys = ['alertes_eau', 'alertes_eau_fortes'];

  /// Sonneries de l'appli : gouttes d'eau + carillon
  /// (tool/generate_sounds.py ; res/raw sur Android, .aiff sur iOS).
  static const softSound = 'resource://raw/bois_doux';
  static const loudSound = 'resource://raw/bois_fort';

  /// Vibration « glou-glou-glou… glouuup » : trois gorgées puis une longue.
  static final softVibration =
      Int64List.fromList([0, 90, 70, 90, 70, 90, 250, 450]);

  /// En mode fort, le même rythme joué trois fois.
  static final loudVibration = Int64List.fromList([
    0, 120, 80, 120, 80, 120, 300, 600, 500, //
    120, 80, 120, 80, 120, 300, 600, 500, //
    120, 80, 120, 80, 120, 300, 900,
  ]);
  static const _eveningId = 800000;
  static const _blue = Color(0xFF1CB0F6);

  /// Titre en gras en haut, texte dessous, visage de Reno en rond ;
  /// l'illustration du conseil apparaît quand on déplie la notification.
  static const layout = NotificationLayout.BigPicture;
  static const _green = Color(0xFF58CC02);

  @override
  Future<void> init() async {
    await _notifications.initialize(
      'resource://drawable/ic_notification',
      [
        NotificationChannel(
          channelKey: channelKey,
          channelName: 'Alertes pour boire',
          channelDescription:
              'Gouttes d\'eau et carillon aux heures où tu dois boire',
          importance: NotificationImportance.High,
          defaultColor: _blue,
          ledColor: _blue,
          playSound: true,
          enableVibration: true,
          soundSource: softSound,
          vibrationPattern: softVibration,
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
          soundSource: loudSound,
          vibrationPattern: loudVibration,
          defaultRingtoneType: DefaultRingtoneType.Alarm,
        ),
      ],
      languageCode: 'fr',
    );
    // Anciens canaux (son du téléphone) : retirés des réglages.
    for (final key in _oldChannelKeys) {
      try {
        await _notifications.removeChannel(key);
      } catch (_) {}
    }
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
        largeIcon: message.avatar,
        roundedLargeIcon: true,
        bigPicture: 'asset://assets/notif/mascot_sad.png',
        notificationLayout: layout,
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
        channelKey: (action.channelKey ?? '').startsWith('alertes_eau_fortes')
            ? loudChannelKey
            : channelKey,
        title: action.title,
        body: action.body,
        // Reno s'inquiète un peu : c'est la deuxième fois.
        largeIcon: 'asset://assets/notif/reno_mood_1.png',
        roundedLargeIcon: true,
        bigPicture: action.bigPicture,
        notificationLayout: layout,
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
      largeIcon: message.avatar,
      roundedLargeIcon: true,
      bigPicture: notificationImage(tip.asset),
      notificationLayout: layout,
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
