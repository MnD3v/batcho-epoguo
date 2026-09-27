import 'dart:io';

import 'package:bois_et_vis/data/hydration_store.dart';
import 'package:bois_et_vis/data/kidney_tips.dart';
import 'package:bois_et_vis/hydration_controller.dart';
import 'package:bois_et_vis/services/home_widget_sync.dart';
import 'package:bois_et_vis/services/reminder_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

void main() {
  Future<HydrationController> at(int hour, int minute) async {
    SharedPreferences.setMockInitialValues(setUpPrefs);
    return HydrationController(
      store: await HydrationStore.load(),
      scheduler: FakeScheduler(),
      clock: () => DateTime(2026, 9, 27, hour, minute),
    );
  }

  test('« J\'ai bu » depuis la notification coche l\'alerte donnée', () async {
    final c = await at(9, 5);
    final reward = await c.quickCheck(minutes: 9 * 60);
    expect(reward?.xp, 10);
    expect(c.checkedCount, 1);
    // Un deuxième appui ne décoche pas.
    expect(await c.quickCheck(minutes: 9 * 60), isNull);
    expect(c.checkedCount, 1);
    // Une alerte qui n'existe plus est ignorée.
    expect(await c.quickCheck(minutes: 8 * 60), isNull);
  });

  test('le widget coche l\'alerte en cours, sinon la dernière oubliée',
      () async {
    final c = await at(12, 30);
    expect(c.quickCheckTarget?.time, '11:00');
    await c.quickCheck();
    expect(c.quickCheckTarget?.time, '09:00');
    await c.quickCheck();
    await c.quickCheck();
    expect(c.quickCheckTarget, isNull);
    expect(await c.quickCheck(), isNull);
  });

  test('ce que montre le widget', () async {
    final c = await at(10, 15);
    var data = HomeWidgetSync.widgetData(c);
    expect(data['drunk'], '0 L');
    expect(data['goal'], 'sur 1,75 L');
    expect(data['status'], 'C\'est l\'heure : 0,25 L');
    expect(data['canCheck'], true);

    await c.quickCheck();
    await c.quickCheck(); // 7h, oubliée
    data = HomeWidgetSync.widgetData(c);
    expect(data['drunk'], '0,5 L');
    expect(data['progress'], 28);
    expect(data['status'], 'Prochaine alerte à 11:00');
    expect(data['canCheck'], false);
  });

  test('les données cochées ailleurs sont relues', () async {
    final c = await at(10, 15);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('checks_2026-09-27', ['540:250']);
    await c.reload();
    expect(c.drunkMl, 250);
  });

  test('chaque conseil a son image de notification', () {
    for (final tip in kidneyTips) {
      final path = notificationImage(tip.asset).replaceFirst('asset://', '');
      expect(File(path).existsSync(), isTrue, reason: path);
    }
    expect(File('assets/notif/reno_face.png').existsSync(), isTrue);
  });
}
