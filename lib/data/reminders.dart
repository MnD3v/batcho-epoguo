/// Rappels de 7h à 20h, toutes les 2 heures.
const reminderHours = [7, 9, 11, 13, 15, 17, 19];

String formatHour(int hour) => '${hour.toString().padLeft(2, '0')}:00';

/// Créneau en cours (on a 2 heures pour boire), ou null hors des créneaux.
int? currentSlotIndex(DateTime now) {
  for (var i = reminderHours.length - 1; i >= 0; i--) {
    final hour = reminderHours[i];
    if (now.hour >= hour) return now.hour < hour + 2 ? i : null;
  }
  return null;
}

/// Prochain rappel de la journée, ou null si c'est fini pour aujourd'hui.
int? nextSlotIndex(DateTime now) {
  for (var i = 0; i < reminderHours.length; i++) {
    if (reminderHours[i] > now.hour) return i;
  }
  return null;
}
