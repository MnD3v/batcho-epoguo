import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/alert_messages.dart';
import '../data/kidney_tips.dart';
import '../models/plan.dart';
import '../models/profile.dart';
import 'reminder_scheduler.dart';

/// Alertes Android façon Duolingo : notification « conversation » avec le
/// gros visage de Reno à gauche, le titre en gras et le texte dessous.
/// Programmées, affichées et gérées en natif (android/…/Alerts.kt,
/// AlertNotifier.kt, AlertReceiver.kt) ; awesome_notifications ne sert plus
/// qu'à demander les autorisations.
class AndroidReminderScheduler implements ReminderScheduler {
  AndroidReminderScheduler({required this.permissions});

  /// Autorisations (notifications, heure exacte).
  final AwesomeReminderScheduler permissions;

  static const _channel = MethodChannel('boisetvis/alerts');

  /// Mêmes numéros que dans AlertReceiver.kt.
  static const rescueId = 800000;
  static const testId = 1;

  @override
  Future<void> init() async {
    await permissions.init();
    // Anciennes alertes awesome_notifications (versions précédentes).
    try {
      await AwesomeNotifications().cancelAllSchedules();
    } catch (_) {}
  }

  @override
  Future<bool> requestPermission() => permissions.requestPermission();

  @override
  Future<void> scheduleAll(
    HydrationPlan plan,
    UserProfile? profile, {
    bool loud = false,
  }) =>
      _call('scheduleWeekly', {
        'alerts': weeklyAlerts(plan, profile, loud: loud),
      });

  @override
  Future<void> showTest(
    Reminder reminder,
    UserProfile? profile, {
    bool loud = false,
  }) =>
      _call(
        'showNow',
        alertData(
          id: testId,
          reminder: reminder,
          profile: profile,
          weekday: DateTime.now().weekday,
          slot: 0,
          loud: loud,
        ),
      );

  @override
  Future<void> scheduleEveningRescue(
    DateTime? at,
    AlertMessage? message,
  ) async {
    if (at == null || message == null) {
      return _call('cancel', {'id': rescueId});
    }
    // La flamme est de nouveau en danger : l'alerte du soir doit sonner
    // (voir _BackgroundScheduler dans background_actions.dart).
    try {
      await (await SharedPreferences.getInstance()).remove('rescue_off_day');
    } catch (_) {}
    return _call('scheduleOnce', {
      'id': rescueId,
      'title': message.title,
      'body': message.body,
      'mood': message.mood,
      'loud': false,
      'reminderMinutes': -1,
      'at': at.millisecondsSinceEpoch,
    });
  }

  @override
  Future<void> cancelAll() => _call('cancelAll');

  Future<void> _call(String method, [Object? arguments]) async {
    try {
      await _channel.invokeMethod<void>(method, arguments);
    } catch (e) {
      debugPrint('Alertes Android ($method) : $e');
    }
  }

  /// Une alerte par jour de la semaine et par heure, pour varier les
  /// messages et les visages de Reno.
  @visibleForTesting
  static List<Map<String, Object>> weeklyAlerts(
    HydrationPlan plan,
    UserProfile? profile, {
    bool loud = false,
  }) =>
      [
        for (var weekday = DateTime.monday;
            weekday <= DateTime.sunday;
            weekday++)
          for (var i = 0; i < plan.reminders.length; i++)
            alertData(
              id: weekday * 10000 + plan.reminders[i].minutes,
              reminder: plan.reminders[i],
              profile: profile,
              weekday: weekday,
              slot: i,
              loud: loud,
            ),
      ];

  @visibleForTesting
  static Map<String, Object> alertData({
    required int id,
    required Reminder reminder,
    required UserProfile? profile,
    required int weekday,
    required int slot,
    required bool loud,
  }) {
    final message = alertMessage(
      firstName: profile?.firstName,
      reminder: reminder,
      weekday: weekday,
      slot: slot,
    );
    final tip = kidneyTips[tipIndexFor(weekday, slot)];
    return {
      'id': id,
      'title': message.title,
      'body': '${message.body}\n${tip.short}',
      'mood': message.mood,
      'loud': loud,
      'reminderMinutes': reminder.minutes,
      'weekday': weekday,
      'minutes': reminder.minutes,
    };
  }
}
