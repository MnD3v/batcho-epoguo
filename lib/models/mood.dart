import 'package:flutter/material.dart';

import '../theme/duo.dart';
import 'plan.dart';

/// Humeur de Reno selon l'heure et l'eau bue : de « très triste » à
/// « très joyeux ».
enum Mood {
  verySad('Très triste', 'J\'ai très soif… Tu m\'as oublié ?', Duo.red),
  sad('Triste', 'J\'ai soif, tu es en retard sur ton eau.', Duo.orange),
  meh('Bof', 'Un verre d\'eau me ferait du bien.', Duo.goldDark),
  happy('Content', 'Je me sens bien, merci !', Duo.green),
  veryHappy('Très joyeux', 'Je suis au top de ma forme !', Duo.blue);

  const Mood(this.label, this.feeling, this.color);

  final String label;

  /// Ce que Reno ressent, à la première personne.
  final String feeling;
  final Color color;

  /// Visage dans assets/mascot (tool/generate_moods.py).
  String get pose => 'mood_$index';
}

/// Une alerte compte comme « en retard » [grace] minutes après son heure.
const moodGraceMinutes = 30;

/// Compare l'eau bue à ce qu'il fallait avoir bu à [nowMinutes] (minutes
/// depuis minuit) : plus la journée avance sans boire, plus Reno est triste.
Mood moodFor({
  required List<Reminder> reminders,
  required int drunkMl,
  required int goalMl,
  required int nowMinutes,
}) {
  if (goalMl > 0 && drunkMl >= goalMl) return Mood.veryHappy;
  final expected = reminders
      .where((r) => nowMinutes >= r.minutes + moodGraceMinutes)
      .fold(0, (sum, r) => sum + r.ml);
  // Rien d'attendu pour l'instant (tôt le matin).
  if (expected == 0) return drunkMl > 0 ? Mood.happy : Mood.meh;
  final ratio = drunkMl / expected;
  if (ratio >= 1.5) return Mood.veryHappy;
  if (ratio >= 1) return Mood.happy;
  if (ratio >= 0.6) return Mood.meh;
  if (ratio >= 0.3) return Mood.sad;
  return Mood.verySad;
}
