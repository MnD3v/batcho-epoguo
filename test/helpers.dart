import 'package:bois_et_vis/models/plan.dart';
import 'package:bois_et_vis/models/profile.dart';
import 'package:bois_et_vis/services/reminder_scheduler.dart';

class FakeScheduler implements ReminderScheduler {
  HydrationPlan? scheduled;
  UserProfile? scheduledFor;
  int permissionRequests = 0;

  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return true;
  }

  @override
  Future<void> scheduleAll(HydrationPlan plan, UserProfile? profile) async {
    scheduled = plan;
    scheduledFor = profile;
  }

  @override
  Future<void> showTest(Reminder reminder, UserProfile? profile) async {}
}

/// Awa, déjà inscrite, alertes toutes les 2 h de 0,25 L.
const setUpPrefs = <String, Object>{
  'profile_first_name': 'Awa',
  'profile_email': 'awa@exemple.com',
  'profile_intake': 'about1_5L',
  'profile_difficulties': <String>['forget'],
  'plan_rhythm': 'every2h',
  'plan_reminders': <String>[
    '420:250',
    '540:250',
    '660:250',
    '780:250',
    '900:250',
    '1020:250',
    '1140:250',
  ],
};
