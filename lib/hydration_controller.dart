import 'dart:async';

import 'package:flutter/foundation.dart';

import 'data/hydration_store.dart';
import 'data/alert_messages.dart';
import 'data/kidney_tips.dart';
import 'models/city.dart';
import 'models/game.dart';
import 'models/plan.dart';
import 'models/profile.dart';
import 'services/auth_service.dart';
import 'services/reminder_scheduler.dart';
import 'services/user_repository.dart';
import 'services/weather_service.dart';

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
    this.cloud,
    this.weather,
    DateTime Function()? clock,
  })  : _store = store,
        _clock = clock ?? DateTime.now {
    _loadAll();
    if (isSetUp) store.markFirstDay(_day);
  }

  final HydrationStore _store;
  final ReminderScheduler scheduler;

  /// Sauvegarde en ligne ; null dans les tests qui n'en ont pas besoin.
  final UserRepository? cloud;

  /// Météo du jour (mode chaleur) ; null dans les tests qui n'en ont pas besoin.
  final WeatherService? weather;
  final DateTime Function() _clock;

  UserProfile? _profile;
  HydrationPlan? _plan;
  late GameStats _stats;
  String? _uid;
  late DateTime _day;
  late Map<int, int> _checks;
  late List<ExtraDrink> _extras;
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

  /// Total bu aujourd'hui : alertes cochées et verres bus à tout moment.
  int get drunkMl =>
      _checks.values.fold(0, (sum, ml) => sum + ml) +
      _extras.fold(0, (sum, e) => sum + e.ml);

  /// Verres bus en dehors des alertes aujourd'hui.
  List<ExtraDrink> get extras => List.unmodifiable(_extras);
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

  /// Connexion : récupère la sauvegarde en ligne si le téléphone ne contient
  /// pas déjà les données de ce compte.
  Future<void> onSignedIn(AppUser user) async {
    _uid = user.uid;
    if (_store.ownerUid != user.uid) {
      await scheduler.cancelAll();
      Map<String, dynamic>? remote;
      try {
        remote = await cloud?.load(user.uid);
      } catch (e) {
        debugPrint('Sauvegarde en ligne indisponible : $e');
      }
      final data = remote?['data'];
      if (data is Map) {
        await _store.importData(Map<String, dynamic>.from(data));
      } else if (_store.ownerUid != null) {
        // Données d'un autre compte : on repart de zéro.
        await _store.clearUserData();
      }
      // Sinon, données d'avant la connexion : on les garde pour ce compte.
      await _store.setOwner(user.uid);
      _loadAll();
      final plan = _plan;
      if (plan != null) await rescheduleAlerts();
      if (data is! Map) _push();
    }
    await protectStreak();
    // Le prénom du compte fait foi (il peut changer dans les paramètres).
    final profile = _profile;
    final name = user.firstName ?? profile?.firstName;
    if (profile != null &&
        (name != profile.firstName || user.email != profile.email)) {
      await saveProfile(profile.copyWith(firstName: name, email: user.email));
    }
    notifyListeners();
  }

  /// Déconnexion : le téléphone oublie tout et ne sonne plus.
  Future<void> onSignedOut() async {
    _uid = null;
    await scheduler.cancelAll();
    await _store.clearUserData();
    _loadAll();
    notifyListeners();
  }

  /// Change le prénom affiché et dans les alertes.
  Future<void> renameTo(String firstName) async {
    final profile = _profile;
    if (profile == null) return;
    await saveProfile(profile.copyWith(firstName: firstName));
    final plan = _plan;
    if (plan != null) await rescheduleAlerts();
  }

  /// Supprime la sauvegarde en ligne (avant de supprimer le compte).
  Future<void> deleteCloudData() async {
    final uid = _uid;
    if (uid != null) await cloud?.delete(uid);
  }

  /// Envoie l'état actuel en ligne, sans bloquer l'écran.
  void _push() {
    final uid = _uid;
    final repo = cloud;
    if (uid == null || repo == null) return;
    final profile = _profile;
    unawaited(
      repo.save(uid, {
        'firstName': profile?.firstName,
        'email': profile?.email,
        'usualIntake': profile?.usualIntake.label,
        'difficulties': [
          for (final d in profile?.difficulties ?? const <Difficulty>{})
            d.label,
        ],
        'rhythm': _plan?.rhythm.label,
        'dailyGoalMl': _plan?.goalMl,
        'xp': xp,
        'data': _store.exportData(),
      }).catchError((Object e) => debugPrint('Sauvegarde en ligne : $e')),
    );
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
      protectStreak();
    }
  }

  /// Alerte à cocher depuis la notification ou le widget : celle de
  /// [minutes] si elle est donnée, sinon l'alerte en cours, sinon la
  /// dernière oubliée.
  Reminder? get quickCheckTarget {
    final current = currentIndex;
    if (current != null && !isChecked(reminders[current])) {
      return reminders[current];
    }
    for (var i = reminders.length - 1; i >= 0; i--) {
      if (slotState(i) == SlotState.missed) return reminders[i];
    }
    return null;
  }

  /// Coche sans ouvrir l'appli ; ne décoche jamais.
  Future<Reward?> quickCheck({int? minutes}) async {
    refreshDay();
    final target = minutes == null
        ? quickCheckTarget
        : reminders.where((r) => r.minutes == minutes).firstOrNull;
    if (target == null || isChecked(target)) return null;
    return toggle(target);
  }

  /// Relit les données du téléphone (modifiées par la notification ou le
  /// widget pendant que l'appli était en arrière-plan).
  Future<void> reload() async {
    final before = _store.checks(_day);
    final extrasBefore = _extras.length;
    await _store.reload();
    _loadAll();
    if (!mapEquals(before, _checks) || extrasBefore != _extras.length) {
      notifyListeners();
      _push();
      await updateEveningRescue();
    }
    await protectStreak();
  }

  /// Enregistre le questionnaire du premier lancement.
  Future<void> saveProfile(UserProfile profile) async {
    _profile = profile;
    notifyListeners();
    await _store.saveProfile(profile);
    await _store.markFirstDay(_day);
    _push();
  }

  /// Enregistre les alertes et les programme sur le téléphone.
  Future<void> savePlan(HydrationPlan plan) async {
    _plan = plan;
    _streak = _store.streak(_day, plan.streakMinChecks);
    notifyListeners();
    await _store.savePlan(plan);
    _push();
    await scheduler.requestPermission();
    await rescheduleAlerts();
  }

  /// Sonnerie de réveil au lieu du son de notification.
  bool get loudAlerts => _store.loudAlerts;

  Future<void> setLoudAlerts(bool loud) async {
    await _store.setLoudAlerts(loud);
    notifyListeners();
    _push();
    await rescheduleAlerts();
  }

  /// Reprogramme toutes les alertes (et celle du soir).
  Future<void> rescheduleAlerts() async {
    final plan = _plan;
    if (plan == null) return;
    await scheduler.scheduleAll(plan, _profile, loud: loudAlerts);
    await updateEveningRescue();
  }

  /// Heure de l'alerte du soir : une heure après la dernière alerte, au
  /// plus tard à 21h30 ; null si la flamme est déjà assurée ou si c'est passé.
  DateTime? get eveningRescueTime {
    if (reminders.isEmpty || streakSafeToday) return null;
    final minutes = (reminders.last.minutes + 60).clamp(0, 21 * 60 + 30);
    final at = _day.add(Duration(minutes: minutes));
    return at.isAfter(now()) ? at : null;
  }

  /// « Ta flamme est en danger » le soir, seulement quand c'est utile.
  Future<void> updateEveningRescue() async {
    final at = eveningRescueTime;
    await scheduler.scheduleEveningRescue(
      at,
      at == null
          ? null
          : eveningRescueMessage(
              firstName: _profile?.firstName,
              streak: _streak,
              remaining: streakMinChecks - checkedCount,
            ),
    );
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
    final streakBefore = _streak;
    await _store.saveChecks(_day, _checks);
    _streak = _store.streak(_day, streakMinChecks);
    final freezeEarned = await _awardFreeze();
    final milestone =
        _streak > streakBefore && streakMilestones.contains(_streak)
            ? _streak
            : null;
    _stats = before.copyWith(
      totalChecks: before.totalChecks + (checked ? 1 : -1),
      totalMl: before.totalMl + (checked ? reminder.ml : -removedMl),
      perfectDays: perfectDays,
      bestStreak: _streak > before.bestStreak ? _streak : before.bestStreak,
    );
    await updateEveningRescue();
    return _finish(
      before,
      goalReached: goalReached && !wasPerfect,
      freezeEarned: freezeEarned,
      streakMilestone: milestone,
    );
  }

  // --- Mode chaleur ---

  City? get city => cityNamed(_store.city);

  /// Température maximale prévue aujourd'hui dans sa ville (si connue).
  double? get todayMax {
    final c = city;
    return c == null ? null : _store.cachedMax(_day, c.name);
  }

  bool get isHotToday => (todayMax ?? 0) >= hotDayCelsius;

  Future<void> setCity(City city) async {
    await _store.setCity(city.name);
    notifyListeners();
    _push();
    await refreshWeather();
  }

  /// Une requête par jour au plus ; sans réseau, pas de mode chaleur.
  Future<void> refreshWeather() async {
    final c = city;
    final service = weather;
    if (c == null || service == null || todayMax != null) return;
    final max = await service.todayMax(c);
    if (max == null) return;
    await _store.cacheMax(_day, c.name, max);
    notifyListeners();
  }

  /// Proposer le compte une fois, après la première alerte cochée sans compte.
  bool get shouldPromptAccount =>
      _uid == null && !_store.accountPromptShown && _stats.totalChecks > 0;

  Future<void> markAccountPromptShown() => _store.markAccountPromptShown();

  /// Compte connecté (null hors connexion).
  String? get uid => _uid;

  /// Lundi de la semaine en cours (clé des défis entre amis).
  DateTime get weekStart =>
      DateTime(_day.year, _day.month, _day.day - (_day.weekday - 1));

  String get weekKey =>
      '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-'
      '${weekStart.day.toString().padLeft(2, '0')}';

  /// Litres bus depuis lundi (millilitres).
  int get weekMl {
    var total = 0;
    for (var d = weekStart;
        !d.isAfter(_day);
        d = DateTime(d.year, d.month, d.day + 1)) {
      total += _store.drunkMl(d);
    }
    return total;
  }

  /// XP offerts (parrainage).
  Future<Reward> addBonusXp(int xp) async {
    final before = _stats;
    _stats = before.copyWith(bonusXp: before.bonusXp + xp);
    return _finish(before);
  }

  /// « + J'ai bu » : un verre bu à tout moment, en dehors des alertes.
  /// Compte dans le total du jour ; +5 XP les 4 premières fois de la
  /// journée. Ne coche pas d'alerte (la flamme récompense la régularité).
  Future<Reward> drinkExtra(int ml) async {
    refreshDay();
    final before = _stats;
    final earnsXp = _extras.length < maxExtraDrinksWithXp;
    final n = now();
    _extras = [..._extras, ExtraDrink(n.hour * 60 + n.minute, ml)];
    await _store.saveExtras(_day, _extras);
    _stats = before.copyWith(
      totalMl: before.totalMl + ml,
      extraDrinks: before.extraDrinks + (earnsXp ? 1 : 0),
    );
    return _finish(before);
  }

  /// Annule un verre noté par erreur (et ses XP).
  Future<void> removeExtra(ExtraDrink drink) async {
    final index = _extras.indexOf(drink);
    if (index < 0) return;
    final before = _stats;
    final earnedBefore = _extras.length.clamp(0, maxExtraDrinksWithXp);
    _extras = [..._extras]..removeAt(index);
    final earnedAfter = _extras.length.clamp(0, maxExtraDrinksWithXp);
    await _store.saveExtras(_day, _extras);
    _stats = before.copyWith(
      totalMl: before.totalMl - drink.ml,
      extraDrinks: before.extraDrinks - (earnedBefore - earnedAfter),
    );
    await _finish(before);
  }

  /// Leçon lue : +5 XP la première fois.
  Future<Reward> markTipRead(int index) async {
    if (isTipRead(index)) return const Reward();
    final before = _stats;
    _stats = before.copyWith(readTips: {...before.readTips, index});
    return _finish(before);
  }

  Future<Reward> _finish(
    GameStats before, {
    bool goalReached = false,
    bool freezeEarned = false,
    int? streakMilestone,
  }) async {
    final newBadges = [
      for (final badge in Achievement.values)
        if (!_stats.badges.contains(badge) && _earned(badge)) badge,
    ];
    if (newBadges.isNotEmpty) {
      _stats = _stats.copyWith(badges: {..._stats.badges, ...newBadges});
    }
    await _store.saveStats(_stats);
    notifyListeners();
    _push();
    final oldLevel = levelFor(before.xp);
    return Reward(
      xp: _stats.xp - before.xp,
      goalReached: goalReached,
      badges: newBadges,
      levelUp: level.number > oldLevel.number ? level : null,
      freezeEarned: freezeEarned,
      streakMilestone: streakMilestone,
    );
  }

  // --- Jours de repos ---

  /// Jours de repos en réserve (2 au plus).
  int get freezes => _store.freezes;

  /// Jours protégés à l'instant par un jour de repos (à annoncer une fois).
  int frozenNotice = 0;

  void clearFrozenNotice() {
    frozenNotice = 0;
    notifyListeners();
  }

  /// Tous les 7 jours de flamme : un jour de repos de plus.
  Future<bool> _awardFreeze() async {
    if (_streak == 0) await _store.setFreezeAwardedAt(0);
    if (_streak == 0 ||
        _streak % freezeEvery != 0 ||
        _streak <= _store.freezeAwardedAt) {
      return false;
    }
    await _store.setFreezeAwardedAt(_streak);
    if (_store.freezes >= HydrationStore.maxFreezes) return false;
    await _store.setFreezes(_store.freezes + 1);
    return true;
  }

  /// Jours oubliés depuis hier : un jour de repos les protège, si la flamme
  /// brûlait avant et qu'il en reste assez.
  Future<void> protectStreak() async {
    final min = streakMinChecks;
    final available = _store.freezes;
    final first = _store.firstDay;
    if (min == 0 || available == 0 || first == null) return;
    final missed = <DateTime>[];
    var day = DateTime(_day.year, _day.month, _day.day - 1);
    while (!_store.keepsStreak(day, min)) {
      if (day.isBefore(first) || missed.length == available) return;
      missed.add(day);
      day = DateTime(day.year, day.month, day.day - 1);
    }
    if (missed.isEmpty) return;
    for (final m in missed) {
      await _store.freezeDay(m);
    }
    await _store.setFreezes(available - missed.length);
    _streak = _store.streak(_day, min);
    frozenNotice = missed.length;
    notifyListeners();
    _push();
  }

  bool _earned(Achievement badge) => switch (badge) {
        Achievement.firstSip => _stats.totalChecks >= 1,
        Achievement.perfectDay => _stats.perfectDays >= 1,
        Achievement.streak3 => _streak >= 3,
        Achievement.streak7 => _streak >= 7,
        Achievement.streak30 => _streak >= 30,
        Achievement.streak100 => _streak >= 100,
        Achievement.earlyBird =>
          reminders.isNotEmpty && isChecked(reminders.first),
        Achievement.nightOwl =>
          reminders.length > 1 && isChecked(reminders.last),
        Achievement.liters10 => _stats.totalMl >= 10000,
        Achievement.liters50 => _stats.totalMl >= 50000,
        Achievement.allTips => _stats.readTips.length == kidneyTips.length,
      };

  void _loadAll() {
    _profile = _store.profile;
    _plan = _store.plan;
    _stats = _store.stats;
    _loadDay();
  }

  void _loadDay() {
    _day = _today();
    _checks = _store.checks(_day);
    _extras = _store.extras(_day);
    _streak = _store.streak(_day, streakMinChecks);
  }

  DateTime _today() {
    final now = _clock();
    return DateTime(now.year, now.month, now.day);
  }
}
