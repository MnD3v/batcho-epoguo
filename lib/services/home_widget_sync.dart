import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../hydration_controller.dart';
import '../models/plan.dart';

/// Envoie l'état du jour au widget de l'écran d'accueil (Android).
abstract final class HomeWidgetSync {
  /// Classe Kotlin du widget (android/app/src/main/kotlin/…).
  static const androidName = 'HydrationWidgetProvider';

  /// Adresse appelée par le bouton « J'ai bu ✓ » du widget.
  static final drankUri = Uri.parse('boisetvis://drank');

  static Future<void> push(HydrationController c) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final data = widgetData(c);
      for (final e in data.entries) {
        await HomeWidget.saveWidgetData(e.key, e.value);
      }
      await HomeWidget.updateWidget(androidName: androidName);
    } catch (e) {
      debugPrint('Widget : $e');
    }
  }

  /// Ce que le widget affiche.
  @visibleForTesting
  static Map<String, Object> widgetData(HydrationController c) {
    final goal = c.goalMl;
    final target = c.quickCheckTarget;
    final next = c.nextIndex;
    final status = !c.isSetUp
        ? 'Ouvre l\'appli pour commencer'
        : c.goalReached
            ? 'Objectif atteint, bravo !'
            : target != null
                ? 'C\'est l\'heure : ${formatLiters(target.ml)}'
                : next != null
                    ? 'Prochaine alerte à ${c.reminders[next].time}'
                    : 'À demain !';
    return {
      'drunk': formatLiters(c.drunkMl),
      'goal': 'sur ${formatLiters(goal)}',
      'progress': goal == 0 ? 0 : (c.drunkMl * 100 ~/ goal).clamp(0, 100),
      'status': status,
      'streak': '${c.streak}',
      'canCheck': target != null,
    };
  }
}
