import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/kidney_tips.dart';
import '../hydration_controller.dart';
import '../models/city.dart';
import '../models/plan.dart';
import '../theme/duo.dart';
import '../services/auth_service.dart';
import '../widgets/account_prompt.dart';
import '../widgets/duo_widgets.dart';
import '../widgets/motion.dart';
import '../widgets/reward_feedback.dart';

/// Le parcours du jour : les 7 rappels en zigzag, à cocher un par un.
class PathScreen extends StatefulWidget {
  const PathScreen({super.key, required this.controller, required this.auth});

  final HydrationController controller;
  final AuthService auth;

  @override
  State<PathScreen> createState() => _PathScreenState();
}

class _PathScreenState extends State<PathScreen> with WidgetsBindingObserver {
  late final Timer _ticker;

  HydrationController get _c => widget.controller;

  /// Décalage horizontal de chaque étape, pour dessiner le chemin.
  static const _zigzag = [0.0, 0.45, 0.7, 0.45, 0.0, -0.45, -0.7];

  /// Étape à faire : la liste y glisse à l'ouverture.
  final _focusKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _focusKey.currentContext;
      if (target == null || !mounted || !Motion.enabled(context)) return;
      Scrollable.ensureVisible(
        target,
        alignment: 0.4,
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeInOutCubic,
      );
    });
    WidgetsBinding.instance.addObserver(this);
    // Met à jour l'étape en cours chaque minute.
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) => _refresh());
  }

  @override
  void dispose() {
    _ticker.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  /// Nouveau jour, nouvelle heure, et ce qui a été coché depuis la
  /// notification ou le widget.
  Future<void> _refresh() async {
    _c.refreshDay();
    await _c.reload();
    await _c.refreshWeather();
    if (mounted) setState(() {});
  }

  Future<void> _onTapSlot(int index) async {
    final reminder = _c.reminders[index];
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    switch (_c.slotState(index)) {
      case SlotState.locked:
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Cette alerte s\'ouvre à ${reminder.time} 🔒 Tu as déjà bu ? '
              'Touche « Je viens de boire ».',
            ),
          ),
        );
      case SlotState.done:
        if (await _confirmUncheck(reminder) == true) await _c.toggle(reminder);
      case SlotState.current || SlotState.missed:
        final reward = await _c.toggle(reminder);
        if (!mounted) return;
        final tip = kidneyTips[tipIndexFor(_c.now().weekday, index)];
        await showReward(context, reward, message: tip.short);
        // Sans compte : proposé une fois, juste après la première gorgée.
        if (mounted) await maybePromptAccount(context, widget.auth, _c);
    }
  }

  /// « Je viens de boire » : un verre à tout moment, en dehors des alertes.
  Future<void> _drinkExtra() async {
    final ml = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (context) => const _ExtraDrinkSheet(),
    );
    if (ml == null || !mounted) return;
    final reward = await _c.drinkExtra(ml);
    if (!mounted) return;
    await showReward(
      context,
      reward,
      message: 'Noté : ${formatLiters(ml)} en plus aujourd\'hui. Boire en '
          'dehors des alertes, c\'est encore mieux !',
    );
    if (mounted) await maybePromptAccount(context, widget.auth, _c);
  }

  Future<bool?> _confirmUncheck(Reminder reminder) =>
      showModalBottomSheet<bool>(
        context: context,
        backgroundColor: Colors.white,
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Décocher l\'alerte de ${reminder.time} ?',
                  style: Duo.heading,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Les XP gagnés seront retirés.',
                  style: Duo.body,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                DuoButton(
                  label: 'Décocher',
                  color: Duo.red,
                  shadow: Duo.redDark,
                  onPressed: () => Navigator.of(context).pop(true),
                ),
                const SizedBox(height: 10),
                DuoButton.outline(
                  label: 'Annuler',
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _c,
      builder: (context, _) {
        return SafeArea(
          child: Column(
            children: [
              _TopBar(controller: _c),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    _DayBanner(controller: _c),
                    const SizedBox(height: 16),
                    _HeatCard(controller: _c),
                    if (_c.frozenNotice > 0) ...[
                      _FrozenNotice(controller: _c),
                      const SizedBox(height: 16),
                    ],
                    _mascot(),
                    const SizedBox(height: 12),
                    _ExtraDrinks(controller: _c, onDrink: _drinkExtra),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) =>
                          _path(constraints.maxWidth),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _mascot() {
    final reminders = _c.reminders;
    final current = _c.currentIndex;
    final next = _c.nextIndex;
    final name = _c.profile?.firstName ?? '';
    final missed = [
      for (var i = 0; i < reminders.length; i++)
        if (_c.slotState(i) == SlotState.missed) i,
    ];
    final (pose, text) = _c.goalReached
        ? (
            'mascot_cheer',
            'Journée parfaite, $name ! Reviens demain pour garder ta flamme.',
          )
        : current != null && !_c.isChecked(reminders[current])
            ? (
                'mascot_drink',
                '$name, lève-toi et bois ${formatLiters(reminders[current].ml)} ! '
                    'Puis touche l\'étape de ${reminders[current].time}.',
              )
            : missed.isNotEmpty
                ? (
                    'mascot_sad',
                    'Tu as oublié ${missed.length} alerte${missed.length > 1 ? 's' : ''}. '
                        'Pas de panique, tu peux encore rattraper !',
                  )
                : next == 0
                    ? (
                        'mascot_happy',
                        'Salut $name ! Première alerte à ${reminders[0].time}.',
                      )
                    : (
                        'mascot_happy',
                        next == null
                            ? 'Bravo ! Rendez-vous demain à ${reminders[0].time}.'
                            : 'Bravo ! Prochaine alerte à ${reminders[next].time}.',
                      );
    return MascotSays(pose: pose, text: text, size: 96, speakable: true);
  }

  Widget _path(double width) {
    const node = 76.0;
    final amplitude = (width - node) / 2 - 24;
    final reminders = _c.reminders;
    // Reno se poste à côté de l'étape à faire, comme dans Duolingo.
    final (mascotAt, pose) = _mascotStep();
    return Column(
      children: [
        for (var i = 0; i < reminders.length; i++)
          Padding(
            key: i == mascotAt ? _focusKey : null,
            padding: const EdgeInsets.only(bottom: 18),
            child: Stack(
              alignment: Alignment.topCenter,
              clipBehavior: Clip.none,
              children: [
                Transform.translate(
                  offset: Offset(_zigzag[i % _zigzag.length] * amplitude, 0),
                  child: _PathNode(
                    index: i,
                    reminder: reminders[i],
                    state: _c.slotState(i),
                    onTap: () => _onTapSlot(i),
                  ),
                ),
                if (i == mascotAt)
                  Transform.translate(
                    offset: Offset(
                      _zigzag[i % _zigzag.length] > 0
                          ? _zigzag[i % _zigzag.length] * amplitude - 120
                          : _zigzag[i % _zigzag.length] * amplitude + 120,
                      36,
                    ),
                    child: AnimatedMascot(
                      pose: pose,
                      size: 72,
                      onTap: () => _onTapSlot(i),
                    ),
                  ),
              ],
            ),
          ),
        _GoalChest(reached: _c.goalReached),
      ],
    );
  }

  /// Étape où se poste Reno : celle de l'heure, sinon la dernière oubliée,
  /// sinon la prochaine.
  (int?, String) _mascotStep() {
    final current = _c.currentIndex;
    if (current != null && !_c.isChecked(_c.reminders[current])) {
      return (current, 'mascot_drink');
    }
    for (var i = _c.reminders.length - 1; i >= 0; i--) {
      if (_c.slotState(i) == SlotState.missed) return (i, 'mascot_sad');
    }
    return (_c.nextIndex, 'mascot_happy');
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.controller});

  final HydrationController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Duo.border, width: 2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          StatChip(
            icon: 'assets/icons/crown.svg',
            value: 'Niv. ${c.level.number}',
            color: Duo.goldDark,
            semanticLabel: 'Niveau ${c.level.number}, ${c.level.name}',
          ),
          StatChip(
            icon: c.streakSafeToday
                ? 'assets/icons/flame.svg'
                : 'assets/icons/flame_off.svg',
            value: '${c.streak}',
            color: c.streakSafeToday ? Duo.orange : Duo.gray,
            animateIcon: c.streakSafeToday,
            semanticLabel: 'Flamme : ${c.streak} jours',
          ),
          if (c.freezes > 0)
            StatChip(
              icon: 'assets/icons/freeze.svg',
              value: '${c.freezes}',
              color: Duo.blue,
              semanticLabel: '${c.freezes} jour'
                  '${c.freezes > 1 ? 's' : ''} de repos en réserve',
            ),
          StatChip(
            icon: 'assets/icons/xp.svg',
            value: '${c.xp}',
            color: Duo.blue,
            semanticLabel: '${c.xp} XP',
          ),
        ],
      ),
    );
  }
}

/// Grande carte bleue « Je viens de boire » qui s'enfonce quand on appuie.
class _DrinkCard extends StatefulWidget {
  const _DrinkCard({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_DrinkCard> createState() => _DrinkCardState();
}

class _DrinkCardState extends State<_DrinkCard> {
  static const _depth = 5.0;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final offset = _down ? _depth : 0.0;
    return Semantics(
      button: true,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) {
          setState(() => _down = false);
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        child: Padding(
          padding: EdgeInsets.only(top: offset),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
            decoration: BoxDecoration(
              color: Duo.blueLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Duo.blue, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Duo.blueDark,
                  offset: Offset(0, _depth - offset),
                ),
              ],
            ),
            child: Row(
              children: [
                const Pulse(
                  amount: 0.06,
                  child: GameIcon('glass', size: 56),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Je viens de boire',
                        style: Duo.heading.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Duo.blueDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tu peux boire à tout moment, même entre les alertes.',
                        style: Duo.body.copyWith(
                          fontSize: 13,
                          color: Duo.blueDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Duo.blue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// « Je viens de boire » et les verres bus en dehors des alertes aujourd'hui.
class _ExtraDrinks extends StatelessWidget {
  const _ExtraDrinks({required this.controller, required this.onDrink});

  final HydrationController controller;
  final VoidCallback onDrink;

  @override
  Widget build(BuildContext context) {
    final extras = controller.extras;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DrinkCard(onTap: onDrink),
        if (extras.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final drink in extras)
                PopIn(
                  child: InputChip(
                    avatar: const GameIcon('drop', size: 20),
                    label: Text(
                      '${drink.time} · ${formatLiters(drink.ml)}',
                      style: Duo.heading.copyWith(fontSize: 13),
                    ),
                    backgroundColor: Duo.blueLight,
                    side: const BorderSide(color: Duo.blue, width: 1.5),
                    deleteIcon: const Icon(Icons.close_rounded, size: 18),
                    deleteButtonTooltipMessage: 'Annuler',
                    onDeleted: () => controller.removeExtra(drink),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Choix de ce qu'on vient de boire.
class _ExtraDrinkSheet extends StatelessWidget {
  const _ExtraDrinkSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const MascotSays(
              pose: 'mascot_drink',
              size: 80,
              text: 'Super réflexe ! Qu\'est-ce que tu viens de boire ?',
            ),
            const SizedBox(height: 16),
            for (final choice in extraDrinkChoices)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: DuoCard(
                  onTap: () => Navigator.of(context).pop(choice.ml),
                  child: Row(
                    children: [
                      SvgPicture.asset(choice.asset, width: 40, height: 40),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          choice.label,
                          style: Duo.heading.copyWith(fontSize: 16),
                        ),
                      ),
                      Text(
                        formatLiters(choice.ml),
                        style: Duo.heading.copyWith(
                          fontSize: 16,
                          color: Duo.blueDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Mode chaleur : conseil du jour s'il fait très chaud (la ville se choisit
/// dans les paramètres).
class _HeatCard extends StatelessWidget {
  const _HeatCard({required this.controller});

  final HydrationController controller;

  @override
  Widget build(BuildContext context) {
    final city = controller.city;
    final max = controller.todayMax;
    if (city == null || max == null || !controller.isHotToday) {
      return const SizedBox.shrink();
    }
    final text = 'Il fera ${max.round()} °C à ${city.name} aujourd\'hui : bois '
        '$hotDayExtraGlasses verres de plus !';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DuoCard(
        color: const Color(0xFFFFF3E0),
        child: Row(
          children: [
            SvgPicture.asset(
              'assets/illustrations/sun_heat.svg',
              width: 56,
              height: 46,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: Duo.heading.copyWith(
                  fontSize: 15,
                  color: Duo.orangeDark,
                ),
              ),
            ),
            SpeakButton(text: text),
          ],
        ),
      ),
    );
  }
}

/// Choix de la ville pour la météo.
Future<void> pickCity(
  BuildContext context,
  HydrationController controller,
) async {
  final city = await showModalBottomSheet<City>(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Ta ville', style: Duo.heading),
          const SizedBox(height: 4),
          const Text(
            'Pour la météo du jour. Rien d\'autre n\'est partagé.',
            style: Duo.body,
          ),
          const SizedBox(height: 12),
          for (final c in cities)
            ListTile(
              title: Text(c.name, style: Duo.heading.copyWith(fontSize: 16)),
              trailing: c.name == controller.city?.name
                  ? const Icon(Icons.check_rounded, color: Duo.green)
                  : null,
              onTap: () => Navigator.of(context).pop(c),
            ),
        ],
      ),
    ),
  );
  if (city != null) await controller.setCity(city);
}

/// « Ton jour de repos a protégé ta flamme », une seule fois.
class _FrozenNotice extends StatelessWidget {
  const _FrozenNotice({required this.controller});

  final HydrationController controller;

  @override
  Widget build(BuildContext context) {
    final days = controller.frozenNotice;
    return DuoCard(
      color: Duo.blueLight,
      onTap: controller.clearFrozenNotice,
      child: Row(
        children: [
          SvgPicture.asset('assets/icons/freeze.svg', width: 40, height: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              days > 1
                  ? 'Ouf ! $days jours de repos ont protégé ta flamme.'
                  : 'Ouf ! Ton jour de repos a protégé ta flamme.',
              style: Duo.heading.copyWith(fontSize: 15, color: Duo.blueDark),
            ),
          ),
          const Icon(Icons.close_rounded, color: Duo.blueDark),
        ],
      ),
    );
  }
}

class _DayBanner extends StatelessWidget {
  const _DayBanner({required this.controller});

  final HydrationController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final remaining = c.streakMinChecks - c.checkedCount;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Duo.green,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Duo.greenDark, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AUJOURD\'HUI · ${c.checkedCount}/${c.reminders.length} ALERTES',
            style: Duo.label.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${formatLiters(c.drunkMl)} sur ${formatLiters(c.goalMl)}',
                  style: Duo.title.copyWith(color: Colors.white),
                ),
              ),
              // Le verre du jour se remplit à chaque gorgée.
              GlassFill(
                level: c.goalMl == 0 ? 0 : c.drunkMl / c.goalMl,
                size: 48,
                duration: const Duration(milliseconds: 900),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DuoProgressBar(
            value: c.goalMl == 0 ? 0 : c.drunkMl / c.goalMl,
            color: Duo.gold,
            track: Duo.greenDark,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              SvgPicture.asset('assets/icons/flame.svg', width: 22, height: 22),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  remaining > 0
                      ? 'Encore $remaining alerte${remaining > 1 ? 's' : ''} '
                          'pour garder ta flamme'
                      : 'Flamme assurée pour aujourd\'hui !',
                  style: const TextStyle(
                    fontFamily: Duo.font,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Étape du parcours, animée façon Duolingo : apparition en cascade,
/// halo et bulle qui flotte quand c'est l'heure, bouton qui s'enfonce,
/// explosion d'étoiles quand c'est bu, tremblement si c'est verrouillé.
class _PathNode extends StatefulWidget {
  const _PathNode({
    required this.index,
    required this.reminder,
    required this.state,
    required this.onTap,
  });

  final int index;
  final Reminder reminder;
  final SlotState state;
  final VoidCallback onTap;

  @override
  State<_PathNode> createState() => _PathNodeState();
}

class _PathNodeState extends State<_PathNode> with TickerProviderStateMixin {
  static const _size = 76.0;
  static const _depth = 7.0;

  late final _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  bool _down = false;

  @override
  void didUpdateWidget(_PathNode old) {
    super.didUpdateWidget(old);
    // Vient d'être bu : explosion d'étoiles.
    if (old.state != SlotState.done && widget.state == SlotState.done) {
      _burst.forward(from: 0);
    }
    // Vient de s'ouvrir : le cadenas saute.
    if (old.state == SlotState.locked && widget.state != SlotState.locked) {
      _shake.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _burst.dispose();
    _shake.dispose();
    super.dispose();
  }

  void _tap() {
    if (widget.state == SlotState.locked) _shake.forward(from: 0);
    HapticFeedback.lightImpact();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final reminder = widget.reminder;
    final (color, shadow, status) = switch (state) {
      SlotState.done => (Duo.gold, Duo.goldDark, 'Bu !'),
      SlotState.current => (Duo.green, Duo.greenDark, 'C\'est l\'heure'),
      SlotState.missed => (Duo.blue, Duo.blueDark, 'À rattraper'),
      SlotState.locked => (Duo.border, const Color(0xFFCECECE), 'Verrouillé'),
    };
    final icon = switch (state) {
      SlotState.done => const Icon(
          Icons.check_rounded,
          color: Colors.white,
          size: 42,
        ),
      SlotState.locked => SvgPicture.asset(
          'assets/icons/lock.svg',
          width: 34,
          height: 34,
        ),
      _ => Container(
          padding: const EdgeInsets.all(6),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: SvgPicture.asset(
            'assets/drinks/glass.svg',
            width: 34,
            height: 34,
          ),
        ),
    };
    final isCurrent = state == SlotState.current;
    final press = _down ? _depth - 2 : 0.0;

    final circle = AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      width: _size,
      height: _size - 6,
      margin: EdgeInsets.only(top: press, bottom: _depth - press),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: shadow, offset: Offset(0, _depth - press))
        ],
      ),
      alignment: Alignment.center,
      // Nouvelle icône (coche, verre, cadenas) avec un rebond.
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        transitionBuilder: (child, animation) => ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.elasticOut),
          child: child,
        ),
        child: KeyedSubtree(key: ValueKey(state), child: icon),
      ),
    );

    final node = SizedBox(
      width: _size * 1.9,
      height: _size + _depth + 4,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          // Halo qui s'élargit autour de l'étape en cours.
          if (isCurrent)
            LoopBuilder(
              duration: const Duration(milliseconds: 1800),
              builder: (context, t, _) => Transform.scale(
                scale: 1 + 0.55 * t,
                child: Opacity(
                  opacity: (1 - t) * 0.45,
                  child: Container(
                    width: _size,
                    height: _size - 6,
                    decoration: const BoxDecoration(
                      color: Duo.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          Pulse(amount: isCurrent ? 0.05 : 0, child: circle),
          // Étoiles quand l'alerte vient d'être bue.
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _burst,
                builder: (context, _) => _burst.isAnimating
                    ? CustomPaint(painter: _StarBurstPainter(_burst.value))
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );

    return Semantics(
      button: true,
      label: '${reminder.time}, $status',
      excludeSemantics: true,
      child: GestureDetector(
        key: ValueKey('slot_${reminder.time}'),
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: _tap,
        // Apparition en cascade, étape après étape.
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 450 + widget.index * 110),
          curve: Interval(
            (widget.index * 110) / (450 + widget.index * 110),
            1,
            curve: Curves.elasticOut,
          ),
          builder: (context, appear, child) => Opacity(
            opacity: appear.clamp(0.0, 1.0),
            child: Transform.scale(scale: 0.4 + 0.6 * appear, child: child),
          ),
          child: AnimatedBuilder(
            animation: _shake,
            builder: (context, child) => Transform.translate(
              offset: Offset(
                math.sin(_shake.value * math.pi * 6) * 9 * (1 - _shake.value),
                0,
              ),
              child: child,
            ),
            child: Column(
              children: [
                if (isCurrent)
                  // La bulle « BOIS ! » flotte au-dessus de l'étape.
                  LoopBuilder(
                    duration: const Duration(milliseconds: 1600),
                    builder: (context, t, child) => Transform.translate(
                      offset: Offset(0, -4 * math.sin(2 * math.pi * t)),
                      child: child,
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Duo.border, width: 2),
                      ),
                      child: Text(
                        'BOIS !',
                        style: Duo.label.copyWith(
                          color: Duo.green,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                node,
                const SizedBox(height: 4),
                Text(
                  '${reminder.time} · ${formatLiters(reminder.ml)}',
                  style: Duo.heading.copyWith(
                    fontSize: 16,
                    color: state == SlotState.locked ? Duo.gray : Duo.text,
                  ),
                ),
                Text(
                  status,
                  style: Duo.body.copyWith(
                    fontSize: 13,
                    color: state == SlotState.locked ? Duo.gray : shadow,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Étoiles et gouttes qui jaillissent autour d'une étape bue.
class _StarBurstPainter extends CustomPainter {
  _StarBurstPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, 35);
    final fade = (1 - t).clamp(0.0, 1.0);
    for (var i = 0; i < 10; i++) {
      final angle = i * 2 * math.pi / 10;
      final distance = 30 + 45 * Curves.easeOut.transform(t);
      final p = center + Offset(math.cos(angle), math.sin(angle)) * distance;
      final paint = Paint()
        ..color = (i.isEven ? Duo.gold : Duo.blue).withValues(alpha: fade);
      if (i.isEven) {
        final star = Path();
        for (var k = 0; k < 10; k++) {
          final r = (k.isEven ? 7.0 : 3.0) * (1 - t * 0.4);
          final a = -math.pi / 2 + k * math.pi / 5;
          final q = p + Offset(math.cos(a) * r, math.sin(a) * r);
          k == 0 ? star.moveTo(q.dx, q.dy) : star.lineTo(q.dx, q.dy);
        }
        canvas.drawPath(star..close(), paint);
      } else {
        canvas.drawCircle(p, 4 * (1 - t * 0.5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_StarBurstPainter old) => old.t != t;
}

class _GoalChest extends StatelessWidget {
  const _GoalChest({required this.reached});

  final bool reached;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Opacity(
          opacity: reached ? 1 : 0.35,
          child: SvgPicture.asset(
            'assets/icons/trophy.svg',
            width: 84,
            height: 84,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          reached ? 'Objectif atteint !' : 'Objectif du jour',
          style: Duo.heading.copyWith(
            fontSize: 16,
            color: reached ? Duo.goldDark : Duo.gray,
          ),
        ),
      ],
    );
  }
}
