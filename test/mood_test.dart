import 'package:bois_et_vis/models/mood.dart';
import 'package:bois_et_vis/models/plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 9h, 11h, 13h, 15h : 0,5 L chacune (2 L par jour).
  const reminders = [
    Reminder(540, 500),
    Reminder(660, 500),
    Reminder(780, 500),
    Reminder(900, 500),
  ];

  Mood at(int hour, int drunkMl, {int minute = 0}) => moodFor(
        reminders: reminders,
        drunkMl: drunkMl,
        goalMl: 2000,
        nowMinutes: hour * 60 + minute,
      );

  test('le matin, avant la première alerte', () {
    expect(at(7, 0), Mood.meh);
    expect(at(7, 250), Mood.happy);
  });

  test('une demi-heure de marge après l\'heure de l\'alerte', () {
    expect(at(9, 0, minute: 20), Mood.meh);
    expect(at(9, 0, minute: 40), Mood.verySad);
  });

  test('plus la journée avance sans boire, plus Reno est triste', () {
    expect(at(12, 1000), Mood.happy);
    expect(at(12, 700), Mood.meh);
    expect(at(12, 400), Mood.sad);
    expect(at(12, 0), Mood.verySad);
    expect(at(16, 500), Mood.verySad);
  });

  test('en avance ou objectif atteint : très joyeux', () {
    expect(at(10, 750), Mood.veryHappy);
    expect(at(20, 2000), Mood.veryHappy);
  });

  test('un visage par humeur', () {
    expect(Mood.values.map((m) => m.pose),
        ['mood_0', 'mood_1', 'mood_2', 'mood_3', 'mood_4']);
  });
}
