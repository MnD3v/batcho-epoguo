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
    this.bonusXp = 0,
    this.extraDrinks = 0,
  });

  final int totalChecks;
  final int totalMl;
  final int perfectDays;
  final int bestStreak;
  final Set<int> readTips;
  final Set<Achievement> badges;

  /// XP offerts (parrainage).
  final int bonusXp;

  /// Verres bus hors alertes qui ont rapporté des XP.
  final int extraDrinks;

  int get xp =>
      totalChecks * xpPerCheck +
      perfectDays * xpPerfectDay +
      readTips.length * xpPerTip +
      extraDrinks * xpPerExtraDrink +
      bonusXp;

  GameStats copyWith({
    int? totalChecks,
    int? totalMl,
    int? perfectDays,
    int? bestStreak,
    Set<int>? readTips,
    Set<Achievement>? badges,
    int? bonusXp,
    int? extraDrinks,
  }) =>
      GameStats(
        totalChecks: totalChecks ?? this.totalChecks,
        totalMl: totalMl ?? this.totalMl,
        perfectDays: perfectDays ?? this.perfectDays,
        bestStreak: bestStreak ?? this.bestStreak,
        readTips: readTips ?? this.readTips,
        badges: badges ?? this.badges,
        bonusXp: bonusXp ?? this.bonusXp,
        extraDrinks: extraDrinks ?? this.extraDrinks,
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
  static const _bonusXpKey = 'stats_bonus_xp';
  static const _extraDrinksKey = 'stats_extra_drinks';
  static const _extraPrefix = 'extra_';
  static const _firstDayKey = 'first_day';

  /// Jour où l'écran d'ouverture a été montré (une fois par jour).
  static const _openingKey = 'opening_day';
  static const _ownerKey = 'owner_uid';

  /// Clés qui appartiennent à la personne connectée (sauvegardées en ligne).
  static const _userPrefixes = [
    'profile_',
    'plan_',
    'checks_',
    'extra_',
    'stats_',
    'social_',
    _firstDayKey,
  ];

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

  /// Alertes façon réveil (sinon son de notification). Sauvegardé avec les
  /// alertes.
  static const _loudKey = 'plan_loud';

  bool get loudAlerts => _prefs.getBool(_loudKey) ?? false;

  Future<void> setLoudAlerts(bool loud) => _prefs.setBool(_loudKey, loud);

  // --- Amis : parrainage et défis ---

  static const _referralCodeKey = 'social_referral_code';
  static const _referredByKey = 'social_referred_by';
  static const _referralsCreditedKey = 'social_referrals_credited';
  static const _challengesKey = 'social_challenges';

  String? get referralCode => _prefs.getString(_referralCodeKey);

  Future<void> setReferralCode(String code) =>
      _prefs.setString(_referralCodeKey, code);

  /// Code d'invitation déjà utilisé (une seule fois par compte).
  String? get referredBy => _prefs.getString(_referredByKey);

  Future<void> setReferredBy(String code) =>
      _prefs.setString(_referredByKey, code);

  /// Amis invités déjà récompensés.
  int get referralsCredited => _prefs.getInt(_referralsCreditedKey) ?? 0;

  Future<void> setReferralsCredited(int n) =>
      _prefs.setInt(_referralsCreditedKey, n);

  /// Codes des défis rejoints.
  List<String> get challengeCodes =>
      _prefs.getStringList(_challengesKey) ?? const [];

  Future<void> setChallengeCodes(List<String> codes) =>
      _prefs.setStringList(_challengesKey, codes);

  // --- Météo (mode chaleur) ---

  static const _cityKey = 'plan_city';
  static const _weatherKey = 'weather_today';

  /// Ville choisie pour la météo.
  String? get city => _prefs.getString(_cityKey);

  Future<void> setCity(String name) => _prefs.setString(_cityKey, name);

  /// Température maximale déjà récupérée pour [day] à [cityName].
  double? cachedMax(DateTime day, String cityName) {
    final parts = (_prefs.getString(_weatherKey) ?? '').split('|');
    if (parts.length != 3 || parts[0] != _dayKey(day) || parts[1] != cityName) {
      return null;
    }
    return double.tryParse(parts[2]);
  }

  Future<void> cacheMax(DateTime day, String cityName, double max) =>
      _prefs.setString(_weatherKey, '${_dayKey(day)}|$cityName|$max');

  // --- Sans compte ---

  static const _accountPromptKey = 'guest_account_prompt';

  /// « Crée ton compte » déjà proposé après la première gorgée.
  bool get accountPromptShown => _prefs.getBool(_accountPromptKey) ?? false;

  Future<void> markAccountPromptShown() =>
      _prefs.setBool(_accountPromptKey, true);

  /// Relit les valeurs écrites par un autre isolate (notification, widget).
  Future<void> reload() => _prefs.reload();

  /// Compte à qui appartiennent les données du téléphone.
  String? get ownerUid => _prefs.getString(_ownerKey);

  Future<void> setOwner(String uid) => _prefs.setString(_ownerKey, uid);

  Iterable<String> get _userKeys =>
      _prefs.getKeys().where((k) => _userPrefixes.any(k.startsWith));

  /// Toutes les données de la personne, pour la sauvegarde en ligne.
  Map<String, Object> exportData() => {
        for (final key in _userKeys)
          if (_prefs.get(key) case final Object value) key: value,
      };

  /// Remplace les données du téléphone par une sauvegarde.
  Future<void> importData(Map<String, dynamic> data) async {
    await clearUserData();
    for (final MapEntry(:key, :value) in data.entries) {
      if (!_userPrefixes.any(key.startsWith)) continue;
      switch (value) {
        case int v:
          await _prefs.setInt(key, v);
        case String v:
          await _prefs.setString(key, v);
        case bool v:
          await _prefs.setBool(key, v);
        case List<dynamic> v:
          await _prefs.setStringList(key, [for (final e in v) '$e']);
      }
    }
  }

  /// Efface les données de la personne (déconnexion, suppression du compte).
  Future<void> clearUserData() async {
    for (final key in _userKeys.toList()) {
      await _prefs.remove(key);
    }
    await _prefs.remove(_ownerKey);
    await _prefs.remove(_accountPromptKey);
  }

  /// Premier jour d'utilisation : les courbes ne montrent rien avant.
  DateTime? get firstDay {
    final text = _prefs.getString(_firstDayKey);
    return text == null ? null : DateTime.tryParse(text);
  }

  bool openingShownOn(DateTime day) =>
      _prefs.getString(_openingKey) == _dayKey(day);

  Future<void> markOpeningShown(DateTime day) =>
      _prefs.setString(_openingKey, _dayKey(day));

  Future<void> markFirstDay(DateTime day) async {
    if (firstDay != null) return;
    await _prefs.setString(_firstDayKey, _dayKey(day));
  }

  /// Total bu un jour donné, en millilitres.
  /// Total bu un jour : alertes cochées et verres bus à tout moment.
  int drunkMl(DateTime day) =>
      checks(day).values.fold(0, (a, b) => a + b) +
      extras(day).fold(0, (a, e) => a + e.ml);

  /// Verres bus en dehors des alertes, dans l'ordre.
  List<ExtraDrink> extras(DateTime day) => [
        for (final entry in (_prefs.getStringList(_extraKey(day)) ?? const [])
            .map((e) => e.split(':')))
          if (entry.length == 2)
            ExtraDrink(int.parse(entry[0]), int.parse(entry[1])),
      ];

  Future<void> saveExtras(DateTime day, List<ExtraDrink> drinks) async {
    if (drinks.isEmpty) {
      await _prefs.remove(_extraKey(day));
    } else {
      await _prefs.setStringList(_extraKey(day), [
        for (final d in drinks) '${d.minutes}:${d.ml}',
      ]);
    }
  }

  static String _extraKey(DateTime day) => '$_extraPrefix${_dayKey(day)}';

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
    if (!keepsStreak(day, minChecks)) {
      day = DateTime(day.year, day.month, day.day - 1);
    }
    var count = 0;
    while (count < _keepDays && keepsStreak(day, minChecks)) {
      // Un jour de repos protège la série sans la faire grandir.
      if (!isFrozen(day)) count++;
      day = DateTime(day.year, day.month, day.day - 1);
    }
    return count;
  }

  /// Jour qui garde la flamme : assez d'alertes cochées, ou jour de repos.
  bool keepsStreak(DateTime day, int minChecks) =>
      checks(day).length >= minChecks || isFrozen(day);

  // --- Jours de repos (protègent la flamme) ---

  static const _freezesKey = 'stats_freezes';
  static const _frozenDaysKey = 'stats_frozen_days';
  static const _freezeAwardedKey = 'stats_freeze_awarded';
  static const maxFreezes = 2;

  /// Jours de repos en réserve.
  int get freezes => _prefs.getInt(_freezesKey) ?? 0;

  Future<void> setFreezes(int value) =>
      _prefs.setInt(_freezesKey, value.clamp(0, maxFreezes));

  /// Longueur de série déjà récompensée par un jour de repos.
  int get freezeAwardedAt => _prefs.getInt(_freezeAwardedKey) ?? 0;

  Future<void> setFreezeAwardedAt(int streak) =>
      _prefs.setInt(_freezeAwardedKey, streak);

  bool isFrozen(DateTime day) =>
      (_prefs.getStringList(_frozenDaysKey) ?? const []).contains(_dayKey(day));

  Future<void> freezeDay(DateTime day) => _prefs.setStringList(
        _frozenDaysKey,
        [...?_prefs.getStringList(_frozenDaysKey), _dayKey(day)],
      );

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
        bonusXp: _prefs.getInt(_bonusXpKey) ?? 0,
        extraDrinks: _prefs.getInt(_extraDrinksKey) ?? 0,
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
    await _prefs.setInt(_bonusXpKey, stats.bonusXp);
    await _prefs.setInt(_extraDrinksKey, stats.extraDrinks);
  }

  Future<void> _pruneOldDays(DateTime today) async {
    final limit = _dayKey(today.subtract(const Duration(days: _keepDays)));
    for (final key in _prefs.getKeys().toList()) {
      for (final prefix in [_checksPrefix, _extraPrefix]) {
        if (key.startsWith(prefix) &&
            key.substring(prefix.length).compareTo(limit) < 0) {
          await _prefs.remove(key);
        }
      }
    }
  }

  static String _checksKey(DateTime day) => '$_checksPrefix${_dayKey(day)}';

  static String _dayKey(DateTime day) =>
      '${day.year}-${_two(day.month)}-${_two(day.day)}';

  static String _two(int n) => n.toString().padLeft(2, '0');
}
