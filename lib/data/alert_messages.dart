import '../models/plan.dart';
import 'kidney_tips.dart';

/// Textes des alertes, qui changent d'une alerte à l'autre pour ne pas
/// devenir invisibles. Une alerte sur deux rappelle le prix d'un rein.
class AlertMessage {
  const AlertMessage(this.title, this.body, {this.mood = 2});

  final String title;
  final String body;

  /// Visage de Reno dans la notification (0 = en larmes … 4 = très
  /// joyeux) : il change d'une alerte à l'autre, comme chez Duolingo.
  final int mood;

  String get avatar => 'asset://assets/notif/reno_mood_$mood.png';
}

AlertMessage alertMessage({
  required String? firstName,
  required Reminder reminder,
  required int weekday,
  required int slot,
}) {
  final name = (firstName ?? '').trim();
  final dose = formatLiters(reminder.ml);
  String hey(String withName, String withoutName) =>
      name.isEmpty ? withoutName : withName.replaceAll('{name}', name);

  final titles = [
    hey('💧 {name}, lève-toi et bois ton eau !',
        '💧 Lève-toi et bois ton eau !'),
    hey('🚰 Pause eau, {name} !', '🚰 Pause eau !'),
    hey('🥵 {name}, Reno a soif !', '🥵 Reno a soif !'),
    hey('⏰ C\'est l\'heure, {name} !', '⏰ C\'est l\'heure !'),
  ];
  final bodies = [
    'Bois $dose maintenant. $kidneyPriceMessage',
    '$dose maintenant, et ta flamme reste allumée 🔥',
    'Bois $dose maintenant. $kidneyPriceMessage',
    'Un petit $dose et tes reins te disent merci.',
  ];
  // Inquiet quand on parle du prix du rein, content quand il remercie.
  const moods = [1, 2, 1, 3];
  final i = weekday + slot;
  return AlertMessage(
    titles[i % titles.length],
    bodies[i % bodies.length],
    // Première alerte du jour : Reno est de bonne humeur.
    mood: slot == 0 ? 3 : moods[i % moods.length],
  );
}

/// Alerte du soir quand la flamme est en danger.
AlertMessage eveningRescueMessage({
  required String? firstName,
  required int streak,
  required int remaining,
}) {
  final name = (firstName ?? '').trim();
  final alerts = '$remaining alerte${remaining > 1 ? 's' : ''}';
  return AlertMessage(
    streak > 0
        ? '🔥 Ta flamme de $streak jour${streak > 1 ? 's' : ''} est en danger !'
        : '🔥 ${name.isEmpty ? 'Allume' : '$name, allume'} ta flamme ce soir !',
    'Coche encore $alerts avant minuit. ${healthyKidneysTip.short}',
    // Reno pleure : la flamme va s'éteindre.
    mood: 0,
  );
}
