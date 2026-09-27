import 'dart:convert';

import 'package:bois_et_vis/data/alert_messages.dart';
import 'package:bois_et_vis/models/plan.dart';
import 'package:bois_et_vis/models/profile.dart';
import 'package:bois_et_vis/services/reminder_scheduler.dart';

class FakeScheduler implements ReminderScheduler {
  HydrationPlan? scheduled;
  UserProfile? scheduledFor;
  int permissionRequests = 0;
  int cancelled = 0;

  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return true;
  }

  bool? scheduledLoud;
  DateTime? eveningAt;
  String? eveningTitle;

  @override
  Future<void> scheduleAll(
    HydrationPlan plan,
    UserProfile? profile, {
    bool loud = false,
  }) async {
    scheduled = plan;
    scheduledFor = profile;
    scheduledLoud = loud;
  }

  @override
  Future<void> showTest(
    Reminder reminder,
    UserProfile? profile, {
    bool loud = false,
  }) async {}

  @override
  Future<void> scheduleEveningRescue(
    DateTime? at,
    AlertMessage? message,
  ) async {
    eveningAt = at;
    eveningTitle = message?.title;
  }

  @override
  Future<void> cancelAll() async {
    cancelled++;
    scheduled = null;
  }
}

/// Awa, déjà inscrite, alertes toutes les 2 h de 0,25 L.
const setUpPrefs = <String, Object>{
  'opening_day': '2026-09-27',
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

const awaUid = 'demo-awa';

/// Le compte démo d'Awa (mot de passe « secret1 »).
final awaAccount = <String, Object>{
  'demo_accounts': jsonEncode({
    awaUid: {
      'email': 'awa@exemple.com',
      'password': 'secret1',
      'firstName': 'Awa',
    },
  }),
};

/// Awa connectée, avec ses alertes sur le téléphone.
final signedInPrefs = <String, Object>{
  ...setUpPrefs,
  ...awaAccount,
  'demo_current_uid': awaUid,
  'owner_uid': awaUid,
};
