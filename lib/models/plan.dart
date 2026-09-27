/// Rythme des alertes choisi par la personne.
enum Rhythm {
  every2h('Toutes les 2 heures', 120),
  every3h('Toutes les 3 heures', 180),
  custom('À des heures précises', 0);

  const Rhythm(this.label, this.stepMinutes);

  final String label;
  final int stepMinutes;
}

/// Une alerte : une heure de la journée et la quantité à boire.
class Reminder {
  const Reminder(this.minutes, this.ml);

  /// Minutes depuis minuit (9h30 → 570).
  final int minutes;
  final int ml;

  int get hour => minutes ~/ 60;
  int get minute => minutes % 60;

  String get time =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  Reminder copyWith({int? minutes, int? ml}) =>
      Reminder(minutes ?? this.minutes, ml ?? this.ml);

  @override
  bool operator ==(Object other) =>
      other is Reminder && other.minutes == minutes && other.ml == ml;

  @override
  int get hashCode => Object.hash(minutes, ml);
}

class HydrationPlan {
  HydrationPlan(this.rhythm, List<Reminder> reminders)
      : reminders = List.unmodifiable(
          [...reminders]..sort((a, b) => a.minutes.compareTo(b.minutes)),
        );

  /// Alertes régulières de 7h à 20h.
  factory HydrationPlan.regular(Rhythm rhythm, int ml) {
    assert(rhythm != Rhythm.custom);
    return HydrationPlan(rhythm, [
      for (var m = firstMinutes; m <= lastMinutes; m += rhythm.stepMinutes)
        Reminder(m, ml),
    ]);
  }

  /// Exemple proposé quand on choisit des heures précises.
  factory HydrationPlan.customExample() => HydrationPlan(Rhythm.custom, const [
        Reminder(9 * 60, 500),
        Reminder(12 * 60, 500),
        Reminder(15 * 60, 500),
        Reminder(18 * 60, 500),
      ]);

  static const firstMinutes = 7 * 60;
  static const lastMinutes = 20 * 60;

  /// Au-delà, iOS ne peut plus programmer une alerte par jour de la semaine.
  static const maxReminders = 8;

  /// Quantités proposées pour une alerte.
  static const doses = [250, 330, 500, 750];

  final Rhythm rhythm;
  final List<Reminder> reminders;

  int get goalMl => reminders.fold(0, (sum, r) => sum + r.ml);

  /// Quantité commune à toutes les alertes (celle de la première).
  int get commonDose => reminders.isEmpty ? 500 : reminders.first.ml;

  /// Alerte en cours : la dernière passée, pendant 3 heures au plus et
  /// jusqu'à l'alerte suivante.
  int? currentIndex(DateTime now) {
    final m = now.hour * 60 + now.minute;
    for (var i = reminders.length - 1; i >= 0; i--) {
      if (m >= reminders[i].minutes) {
        return m < reminders[i].minutes + 180 ? i : null;
      }
    }
    return null;
  }

  /// Prochaine alerte de la journée, ou null si c'est fini pour aujourd'hui.
  int? nextIndex(DateTime now) {
    final m = now.hour * 60 + now.minute;
    for (var i = 0; i < reminders.length; i++) {
      if (reminders[i].minutes > m) return i;
    }
    return null;
  }

  /// Alertes à cocher pour garder sa flamme : 70 % de la journée.
  int get streakMinChecks => (reminders.length * 0.7).ceil();
}

/// 500 → « 0,5 L », 1750 → « 1,75 L ».
String formatLiters(int ml) {
  var text = (ml / 1000).toStringAsFixed(2);
  text = text.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  return '${text.replaceAll('.', ',')} L';
}
