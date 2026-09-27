import 'package:shared_preferences/shared_preferences.dart';

import '../models/game.dart';
import '../models/plan.dart';
import '../models/profile.dart';

/// Totaux cumulés, gardés même quand l'historique ancien est supprimé.
class GameStats {
  const GameStats({
    this.totalChecks = 0,
    this.totalMl = 0,
    this.perfectDays = 0,
    this.bestStreak = 0,
    this.readTips = const {},
    this.badges = const {},
  });

  final int totalChecks;
  final int totalMl;
  final int perfectDays;
  final int bestStreak;
  final Set<int> readTips;
  final Set<Achievement> badges;

  int get xp =>
      totalChecks * xpPerCheck +
      perfectDays * xpPerfectDay +
      readTips.length * xpPerTip;

  GameStats copyWith({
    int? totalChecks,
    int? totalMl,
    int? perfectDays,
    int? bestStreak,
    Set<int>? readTips,
    Set<Achievement>? badges,
  }) =>
      GameStats(
        totalChecks: totalChecks ?? this.totalChecks,
        totalMl: totalMl ?? this.totalMl,
        perfectDays: perfectDays ?? this.perfectDays,
        bestStreak: bestStreak ?? this.bestStreak,
        readTips: readTips ?? this.readTips,
        badges: badges ?? this.badges,
      );
}

/// Sauvegarde locale : la boisson choisie, les rappels cochés par jour et
/// la progression du jeu.
class HydrationStore {
  HydrationStore(this._prefs);

  static Future<HydrationStore> load() async =>
      HydrationStore(await SharedPreferences.getInstance());

  final SharedPreferences _prefs;

  static const _firstNameKey = 'profile_first_name';
  static const _emailKey = 'profile_email';
  static const _intakeKey = 'profile_intake';
  static const _difficultiesKey = 'profile_difficulties';
  static const _rhythmKey = 'plan_rhythm';
  static const _remindersKey = 'plan_reminders';
  static const _checksPrefix = 'checks_';

  /// Un an d'historique suffit pour calculer les séries.
  static const _keepDays = 400;

  static const _totalChecksKey = 'stats_checks';
  static const _totalMlKey = 'stats_ml';
  static const _perfectDaysKey = 'stats_perfect_days';
  static const _bestStreakKey = 'stats_best_streak';
  static const _readTipsKey = 'stats_read_tips';
  static const _badgesKey = 'stats_badges';
  static const _firstDayKey = 'first_day';

  UserProfile? get profile {
    final firstName = _prefs.getString(_firstNameKey);
    if (firstName == null) return null;
    return UserProfile(
      firstName: firstName,
      email: _prefs.getString(_emailKey) ?? '',
      usualIntake: _byName(
        UsualIntake.values,
        _prefs.getString(_intakeKey),
        UsualIntake.about1_5L,
      ),
      difficulties: {
        for (final name in _prefs.getStringList(_difficultiesKey) ?? const [])
          ...Difficulty.values.where((d) => d.name == name),
      },
    );
  }

  /// Premier jour d'utilisation : les courbes ne montrent rien avant.
  DateTime? get firstDay {
    final text = _prefs.getString(_firstDayKey);
    return text == null ? null : DateTime.tryParse(text);
  }

  Future<void> markFirstDay(DateTime day) async {
    if (firstDay != null) return;
    await _prefs.setString(_firstDayKey, _checksKey(day).substring(7));
  }

  /// Total bu un jour donné, en millilitres.
  int drunkMl(DateTime day) => checks(day).values.fold(0, (a, b) => a + b);

  Future<void> saveProfile(UserProfile profile) async {
    await _prefs.setString(_firstNameKey, profile.firstName);
    await _prefs.setString(_emailKey, profile.email);
    await _prefs.setString(_intakeKey, profile.usualIntake.name);
    await _prefs.setStringList(_difficultiesKey, [
      for (final d in profile.difficulties) d.name,
    ]);
  }

  HydrationPlan? get plan {
    final entries = _prefs.getStringList(_remindersKey);
    if (entries == null || entries.isEmpty) return null;
    return HydrationPlan(
      _byName(Rhythm.values, _prefs.getString(_rhythmKey), Rhythm.custom),
      [
        for (final entry in entries.map((e) => e.split(':')))
          if (entry.length == 2)
            Reminder(int.parse(entry[0]), int.parse(entry[1])),
      ],
    );
  }

  Future<void> savePlan(HydrationPlan plan) async {
    await _prefs.setString(_rhythmKey, plan.rhythm.name);
    await _prefs.setStringList(_remindersKey, [
      for (final r in plan.reminders) '${r.minutes}:${r.ml}',
    ]);
  }

  static T _byName<T extends Enum>(List<T> values, String? name, T fallback) =>
      values.where((v) => v.name == name).firstOrNull ?? fallback;

  /// Heure de l'alerte (minutes depuis minuit) → millilitres bus.
  Map<int, int> checks(DateTime day) {
    final entries = _prefs.getStringList(_checksKey(day)) ?? const [];
    return {
      for (final entry in entries.map((e) => e.split(':')))
        if (entry.length == 2) int.parse(entry[0]): int.parse(entry[1]),
    };
  }

  Future<void> saveChecks(DateTime day, Map<int, int> checks) async {
    final key = _checksKey(day);
    if (checks.isEmpty) {
      await _prefs.remove(key);
    } else {
      await _prefs.setStringList(key, [
        for (final e in checks.entries) '${e.key}:${e.value}',
      ]);
    }
    await _pruneOldDays(day);
  }

  /// Jours consécutifs avec au moins [minChecks] alertes cochées,
  /// en comptant aujourd'hui seulement s'il est déjà validé.
  int streak(DateTime today, int minChecks) {
    if (minChecks <= 0) return 0;
    var day = DateTime(today.year, today.month, today.day);
    if (checks(day).length < minChecks) {
      day = DateTime(day.year, day.month, day.day - 1);
    }
    var count = 0;
    while (count < _keepDays && checks(day).length >= minChecks) {
      count++;
      day = DateTime(day.year, day.month, day.day - 1);
    }
    return count;
  }

  GameStats get stats => GameStats(
        totalChecks: _prefs.getInt(_totalChecksKey) ?? 0,
        totalMl: _prefs.getInt(_totalMlKey) ?? 0,
        perfectDays: _prefs.getInt(_perfectDaysKey) ?? 0,
        bestStreak: _prefs.getInt(_bestStreakKey) ?? 0,
        readTips: {
          for (final i
              in _prefs.getStringList(_readTipsKey) ?? const <String>[])
            int.parse(i),
        },
        badges: {
          for (final name
              in _prefs.getStringList(_badgesKey) ?? const <String>[])
            ...Achievement.values.where((b) => b.name == name),
        },
      );

  Future<void> saveStats(GameStats stats) async {
    await _prefs.setInt(_totalChecksKey, stats.totalChecks);
    await _prefs.setInt(_totalMlKey, stats.totalMl);
    await _prefs.setInt(_perfectDaysKey, stats.perfectDays);
    await _prefs.setInt(_bestStreakKey, stats.bestStreak);
    await _prefs.setStringList(_readTipsKey, [
      for (final i in stats.readTips) '$i',
    ]);
    await _prefs.setStringList(_badgesKey, [
      for (final b in stats.badges) b.name,
    ]);
  }

  Future<void> _pruneOldDays(DateTime today) async {
    final limit = _checksKey(today.subtract(const Duration(days: _keepDays)));
    for (final key in _prefs.getKeys().toList()) {
      if (key.startsWith(_checksPrefix) && key.compareTo(limit) < 0) {
        await _prefs.remove(key);
      }
    }
  }

  static String _checksKey(DateTime day) =>
      '$_checksPrefix${day.year}-${_two(day.month)}-${_two(day.day)}';

  static String _two(int n) => n.toString().padLeft(2, '0');
}
