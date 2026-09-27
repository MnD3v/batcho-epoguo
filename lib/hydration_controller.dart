import 'package:flutter/foundation.dart';

import 'data/hydration_store.dart';
import 'data/kidney_tips.dart';
import 'models/game.dart';
import 'models/plan.dart';
import 'models/profile.dart';
import 'services/reminder_scheduler.dart';

enum SlotState { done, current, missed, locked }

/// Un point des courbes d'évolution ; [liters] est nul avant le premier jour
/// d'utilisation.
class ChartPoint {
  const ChartPoint(this.date, this.liters);

  final DateTime date;
  final double? liters;
}

/// État de l'appli : le profil, les alertes, ce qui est coché aujourd'hui et
/// la progression du jeu (XP, niveau, flamme, badges).
class HydrationController extends ChangeNotifier {
  HydrationController({
    required HydrationStore store,
    required this.scheduler,
    DateTime Function()? clock,
  })  : _store = store,
        _clock = clock ?? DateTime.now {
    _profile = store.profile;
    _plan = store.plan;
    _stats = store.stats;
    _loadDay();
    if (isSetUp) store.markFirstDay(_day);
  }

  final HydrationStore _store;
  final ReminderScheduler scheduler;
  final DateTime Function() _clock;

  UserProfile? _profile;
  HydrationPlan? _plan;
  late GameStats _stats;
  late DateTime _day;
  late Map<int, int> _checks;
  late int _streak;

  UserProfile? get profile => _profile;
  HydrationPlan? get plan => _plan;
  bool get isSetUp => _profile != null && _plan != null;
  List<Reminder> get reminders => _plan?.reminders ?? const [];

  GameStats get stats => _stats;
  DateTime now() => _clock();

  int get xp => _stats.xp;
  Level get level => levelFor(xp);
  int get streak => _streak;

  /// Meilleure série, en comptant la série en cours.
  int get bestStreak =>
      _streak > _stats.bestStreak ? _streak : _stats.bestStreak;
  int get streakMinChecks => _plan?.streakMinChecks ?? 0;
  bool get streakSafeToday =>
      streakMinChecks > 0 && _checks.length >= streakMinChecks;

  bool isChecked(Reminder r) => _checks.containsKey(r.minutes);
  int get checkedCount =>
      reminders.where((r) => _checks.containsKey(r.minutes)).length;
  bool get goalReached =>
      reminders.isNotEmpty && checkedCount == reminders.length;
  int get drunkMl => _checks.values.fold(0, (sum, ml) => sum + ml);
  int get goalMl => _plan?.goalMl ?? 0;

  bool isTipRead(int index) => _stats.readTips.contains(index);

  int? get currentIndex => _plan?.currentIndex(now());
  int? get nextIndex => _plan?.nextIndex(now());

  SlotState slotState(int index) {
    final r = reminders[index];
    if (isChecked(r)) return SlotState.done;
    if (index == currentIndex) return SlotState.current;
    final m = now().hour * 60 + now().minute;
    return m >= r.minutes ? SlotState.missed : SlotState.locked;
  }

  /// Litres bus chaque jour, des [count] derniers jours jusqu'à aujourd'hui.
  List<ChartPoint> lastDays(int count) {
    final start = _store.firstDay ?? _day;
    return [
      for (var i = count - 1; i >= 0; i--)
        _dayPoint(DateTime(_day.year, _day.month, _day.day - i), start),
    ];
  }

  ChartPoint _dayPoint(DateTime day, DateTime start) => ChartPoint(
        day,
        day.isBefore(start) ? null : _store.drunkMl(day) / 1000,
      );

  /// Moyenne de litres bus par jour, pour chacun des [count] derniers mois
  /// jusqu'au mois en cours (jours d'utilisation terminés seulement).
  List<ChartPoint> lastMonths(int count) {
    final start = _store.firstDay ?? _day;
    return [
      for (var i = count - 1; i >= 0; i--)
        _monthPoint(DateTime(_day.year, _day.month - i), start),
    ];
  }

  ChartPoint _monthPoint(DateTime month, DateTime start) {
    var total = 0;
    var days = 0;
    for (var d = month;
        d.month == month.month && d.isBefore(_day);
        d = DateTime(d.year, d.month, d.day + 1)) {
      if (d.isBefore(start)) continue;
      total += _store.drunkMl(d);
      days++;
    }
    return ChartPoint(month, days == 0 ? null : total / days / 1000);
  }

  /// Change de jour si minuit est passé depuis le dernier affichage.
  void refreshDay() {
    final today = _today();
    if (today != _day) {
      _loadDay();
      notifyListeners();
    }
  }

  /// Enregistre le questionnaire du premier lancement.
  Future<void> saveProfile(UserProfile profile) async {
    _profile = profile;
    notifyListeners();
    await _store.saveProfile(profile);
    await _store.markFirstDay(_day);
  }

  /// Enregistre les alertes et les programme sur le téléphone.
  Future<void> savePlan(HydrationPlan plan) async {
    _plan = plan;
    _streak = _store.streak(_day, plan.streakMinChecks);
    notifyListeners();
    await _store.savePlan(plan);
    await scheduler.requestPermission();
    await scheduler.scheduleAll(plan, _profile);
  }

  /// Coche ou décoche une alerte ; renvoie ce que ça rapporte.
  Future<Reward> toggle(Reminder reminder) async {
    if (_plan == null) return const Reward();
    refreshDay();
    final before = _stats;
    final wasPerfect = goalReached;
    final removedMl = _checks.remove(reminder.minutes);
    final checked = removedMl == null;
    if (checked) _checks[reminder.minutes] = reminder.ml;

    var perfectDays = before.perfectDays;
    if (goalReached && !wasPerfect) perfectDays++;
    if (!goalReached && wasPerfect) perfectDays--;

    // La série se calcule à partir de l'historique enregistré.
    await _store.saveChecks(_day, _checks);
    _streak = _store.streak(_day, streakMinChecks);
    _stats = before.copyWith(
      totalChecks: before.totalChecks + (checked ? 1 : -1),
      totalMl: before.totalMl + (checked ? reminder.ml : -removedMl),
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
        Achievement.earlyBird =>
          reminders.isNotEmpty && isChecked(reminders.first),
        Achievement.nightOwl =>
          reminders.length > 1 && isChecked(reminders.last),
        Achievement.liters10 => _stats.totalMl >= 10000,
        Achievement.liters50 => _stats.totalMl >= 50000,
        Achievement.allTips => _stats.readTips.length == kidneyTips.length,
      };

  void _loadDay() {
    _day = _today();
    _checks = _store.checks(_day);
    _streak = _store.streak(_day, streakMinChecks);
  }

  DateTime _today() {
    final now = _clock();
    return DateTime(now.year, now.month, now.day);
  }
}
