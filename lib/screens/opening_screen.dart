import 'package:flutter/material.dart';

import '../hydration_controller.dart';
import '../models/plan.dart';
import '../widgets/hero_page.dart';

/// Écran d'ouverture du jour, façon Duolingo : Reno et sa bande, l'objectif
/// du jour et un gros « C'est parti ».
class OpeningScreen extends StatelessWidget {
  const OpeningScreen({
    super.key,
    required this.controller,
    required this.onDone,
  });

  final HydrationController controller;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final name = c.profile?.firstName ?? '';
    final alerts = c.reminders.length;
    final hour = c.now().hour;
    final hello = hour < 12
        ? 'Bonjour'
        : hour < 18
            ? 'Bon après-midi'
            : 'Bonsoir';
    return HeroPage(
      title: name.isEmpty ? '$hello !' : '$hello, $name !',
      badge: c.streak > 0
          ? '🔥 FLAMME DE ${c.streak} JOUR${c.streak > 1 ? 'S' : ''}'
          : '💧 OBJECTIF DU JOUR : ${formatLiters(c.goalMl)}',
      text: c.streak > 0
          ? 'Objectif du jour : ${formatLiters(c.goalMl)}. Bois tes $alerts '
              'alertes pour garder ta flamme et gagner des XP !'
          : 'Reno et sa bande t\'attendent : bois tes $alerts alertes '
              'aujourd\'hui et allume ta flamme !',
      button: 'C\'est parti',
      onPressed: onDone,
      onClose: onDone,
    );
  }
}
