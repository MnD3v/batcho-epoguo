import 'package:bois_et_vis/models/plan.dart';
import 'package:bois_et_vis/models/profile.dart';
import 'package:bois_et_vis/services/android_alerts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('alertes natives : une par jour et par heure, prêtes pour Kotlin', () {
    final plan = HydrationPlan(Rhythm.custom, const [
      Reminder(540, 500),
      Reminder(720, 250),
    ]);
    final alerts = AndroidReminderScheduler.weeklyAlerts(
      plan,
      const UserProfile(
        firstName: 'Awa',
        email: 'awa@exemple.com',
        usualIntake: UsualIntake.about1_5L,
        difficulties: {},
      ),
      loud: true,
    );
    expect(alerts, hasLength(14));
    final monday9 = alerts.first;
    expect(monday9['id'], 10540);
    expect(monday9['weekday'], DateTime.monday);
    expect(monday9['minutes'], 540);
    expect(monday9['reminderMinutes'], 540);
    expect(monday9['loud'], isTrue);
    expect(monday9['mood'], 3); // première alerte du jour : content
    expect(monday9['title'] as String, contains('Awa'));
    expect((alerts.map((a) => a['id']).toSet()), hasLength(14));
  });
}
