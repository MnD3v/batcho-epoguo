import 'package:shared_preferences/shared_preferences.dart';

import '../models/drink.dart';
import '../models/game.dart';

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
  }) => GameStats(
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

  static const _typeKey = 'drink_type';
  static const _unitKey = 'drink_unit_ml';
  static const _countKey = 'drink_units';
  static const _checksPrefix = 'checks_';

  /// Un an d'historique suffit pour calculer les séries.
  static const _keepDays = 400;

  static const _totalChecksKey = 'stats_checks';
  static const _totalMlKey = 'stats_ml';
  static const _perfectDaysKey = 'stats_perfect_days';
  static const _bestStreakKey = 'stats_best_streak';
  static const _readTipsKey = 'stats_read_tips';
  static const _badgesKey = 'stats_badges';

  DrinkSettings? get settings {
    final typeName = _prefs.getString(_typeKey);
    final type = DrinkType.values.where((t) => t.name == typeName).firstOrNull;
    if (type == null) return null;
    return DrinkSettings(
      type: type,
      unitMl: _prefs.getInt(_unitKey) ?? type.defaultSizeMl,
      unitsPerReminder: _prefs.getInt(_countKey) ?? 1,
    );
  }

  Future<void> saveSettings(DrinkSettings settings) async {
    await _prefs.setString(_typeKey, settings.type.name);
    await _prefs.setInt(_unitKey, settings.unitMl);
    await _prefs.setInt(_countKey, settings.unitsPerReminder);
  }

  /// Heure du rappel → millilitres bus à ce rappel.
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

  /// Jours consécutifs avec au moins [streakMinChecks] rappels cochés,
  /// en comptant aujourd'hui seulement s'il est déjà validé.
  int streak(DateTime today) {
    var day = DateTime(today.year, today.month, today.day);
    if (checks(day).length < streakMinChecks) {
      day = DateTime(day.year, day.month, day.day - 1);
    }
    var count = 0;
    while (count < _keepDays && checks(day).length >= streakMinChecks) {
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
      for (final i in _prefs.getStringList(_readTipsKey) ?? const <String>[])
        int.parse(i),
    },
    badges: {
      for (final name in _prefs.getStringList(_badgesKey) ?? const <String>[])
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
