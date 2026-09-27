import 'package:flutter/foundation.dart';

import 'data/hydration_store.dart';
import 'data/kidney_tips.dart';
import 'data/reminders.dart';
import 'models/drink.dart';
import 'models/game.dart';
import 'services/reminder_scheduler.dart';

enum SlotState { done, current, missed, locked }

/// État de l'appli : la boisson choisie, les rappels cochés aujourd'hui et la
/// progression du jeu (XP, niveau, flamme, badges).
class HydrationController extends ChangeNotifier {
  HydrationController({
    required HydrationStore store,
    required this.scheduler,
    DateTime Function()? clock,
  }) : _store = store,
       _clock = clock ?? DateTime.now {
    _settings = store.settings;
    _stats = store.stats;
    _loadDay();
  }

  final HydrationStore _store;
  final ReminderScheduler scheduler;
  final DateTime Function() _clock;

  DrinkSettings? _settings;
  late GameStats _stats;
  late DateTime _day;
  late Map<int, int> _checks;
  late int _streak;

  DrinkSettings? get settings => _settings;
  GameStats get stats => _stats;
  DateTime now() => _clock();

  int get xp => _stats.xp;
  Level get level => levelFor(xp);
  int get streak => _streak;

  /// Meilleure série, en comptant la série en cours.
  int get bestStreak =>
      _streak > _stats.bestStreak ? _streak : _stats.bestStreak;
  bool get streakSafeToday => _checks.length >= streakMinChecks;

  bool isChecked(int hour) => _checks.containsKey(hour);
  int get checkedCount => _checks.length;
  bool get goalReached => _checks.length == reminderHours.length;
  int get drunkMl => _checks.values.fold(0, (sum, ml) => sum + ml);
  int get goalMl => (_settings?.doseMl ?? 0) * reminderHours.length;

  bool isTipRead(int index) => _stats.readTips.contains(index);

  SlotState slotState(int index) {
    final hour = reminderHours[index];
    if (isChecked(hour)) return SlotState.done;
    if (index == currentSlotIndex(now())) return SlotState.current;
    return now().hour >= hour ? SlotState.missed : SlotState.locked;
  }

  /// Change de jour si minuit est passé depuis le dernier affichage.
  void refreshDay() {
    final today = _today();
    if (today != _day) {
      _loadDay();
      notifyListeners();
    }
  }

  /// Coche ou décoche un rappel ; renvoie ce que ça rapporte.
  Future<Reward> toggle(int hour) async {
    final settings = _settings;
    if (settings == null) return const Reward();
    refreshDay();
    final before = _stats;
    final wasPerfect = goalReached;
    final removedMl = _checks.remove(hour);
    if (removedMl == null) _checks[hour] = settings.doseMl;
    final checked = removedMl == null;

    var perfectDays = before.perfectDays;
    if (goalReached && !wasPerfect) perfectDays++;
    if (!goalReached && wasPerfect) perfectDays--;

    // La série se calcule à partir de l'historique enregistré.
    await _store.saveChecks(_day, _checks);
    _streak = _store.streak(_day);
    _stats = before.copyWith(
      totalChecks: before.totalChecks + (checked ? 1 : -1),
      totalMl: before.totalMl + (checked ? settings.doseMl : -removedMl),
      perfectDays: perfectDays,
      bestStreak: _streak > before.bestStreak ? _streak : before.bestStreak,
    );
    return _finish(before, goalReached: goalReached && !wasPerfect);
  }

  /// Leçon lue : +5 XP la première fois.
  Future<Reward> markTipRead(int index) async {
    if (isTipRead(index)) return const Reward();
    final before = _stats;
    _stats = before.copyWith(readTips: {...before.readTips, index});
    return _finish(before);
  }

  Future<void> saveSettings(DrinkSettings settings) async {
    _settings = settings;
    notifyListeners();
    await _store.saveSettings(settings);
    await scheduler.requestPermission();
    await scheduler.scheduleAll(settings);
  }

  Future<Reward> _finish(GameStats before, {bool goalReached = false}) async {
    final newBadges = [
      for (final badge in Achievement.values)
        if (!_stats.badges.contains(badge) && _earned(badge)) badge,
    ];
    if (newBadges.isNotEmpty) {
      _stats = _stats.copyWith(badges: {..._stats.badges, ...newBadges});
    }
    await _store.saveStats(_stats);
    notifyListeners();
    final oldLevel = levelFor(before.xp);
    return Reward(
      xp: _stats.xp - before.xp,
      goalReached: goalReached,
      badges: newBadges,
      levelUp: level.number > oldLevel.number ? level : null,
    );
  }

  bool _earned(Achievement badge) => switch (badge) {
    Achievement.firstSip => _stats.totalChecks >= 1,
    Achievement.perfectDay => _stats.perfectDays >= 1,
    Achievement.streak3 => _streak >= 3,
    Achievement.streak7 => _streak >= 7,
    Achievement.streak30 => _streak >= 30,
    Achievement.earlyBird => isChecked(reminderHours.first),
    Achievement.nightOwl => isChecked(reminderHours.last),
    Achievement.liters10 => _stats.totalMl >= 10000,
    Achievement.liters50 => _stats.totalMl >= 50000,
    Achievement.allTips => _stats.readTips.length == kidneyTips.length,
  };

  void _loadDay() {
    _day = _today();
    _checks = _store.checks(_day);
    _streak = _store.streak(_day);
  }

  DateTime _today() {
    final now = _clock();
    return DateTime(now.year, now.month, now.day);
  }
}
