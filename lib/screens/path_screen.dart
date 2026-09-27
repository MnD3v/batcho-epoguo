import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/kidney_tips.dart';
import '../data/reminders.dart';
import '../hydration_controller.dart';
import '../models/drink.dart';
import '../models/game.dart';
import '../theme/duo.dart';
import '../widgets/duo_widgets.dart';
import '../widgets/reward_feedback.dart';

/// Le parcours du jour : les 7 rappels en zigzag, à cocher un par un.
class PathScreen extends StatefulWidget {
  const PathScreen({super.key, required this.controller});

  final HydrationController controller;

  @override
  State<PathScreen> createState() => _PathScreenState();
}

class _PathScreenState extends State<PathScreen> with WidgetsBindingObserver {
  late final Timer _ticker;

  HydrationController get _c => widget.controller;

  /// Décalage horizontal de chaque étape, pour dessiner le chemin.
  static const _zigzag = [0.0, 0.45, 0.7, 0.45, 0.0, -0.45, -0.7];

  @override
  void initState() {
    super.initState();
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

  void _refresh() {
    _c.refreshDay();
    if (mounted) setState(() {});
  }

  Future<void> _onTapSlot(int index) async {
    final hour = reminderHours[index];
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    switch (_c.slotState(index)) {
      case SlotState.locked:
        messenger.showSnackBar(
          SnackBar(
            content: Text('Ce rappel s\'ouvre à ${formatHour(hour)} 🔒'),
          ),
        );
      case SlotState.done:
        if (await _confirmUncheck(hour) == true) await _c.toggle(hour);
      case SlotState.current || SlotState.missed:
        final reward = await _c.toggle(hour);
        if (!mounted) return;
        final tip = kidneyTips[tipIndexFor(_c.now().weekday, index)];
        await showReward(context, reward, message: tip.short);
    }
  }

  Future<bool?> _confirmUncheck(int hour) => showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.white,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Décocher le rappel de ${formatHour(hour)} ?',
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
        final settings = _c.settings!;
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
                    _mascot(settings),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) =>
                          _path(settings, constraints.maxWidth),
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

  Widget _mascot(DrinkSettings settings) {
    final now = _c.now();
    final current = currentSlotIndex(now);
    final next = nextSlotIndex(now);
    final missed = [
      for (var i = 0; i < reminderHours.length; i++)
        if (_c.slotState(i) == SlotState.missed) i,
    ];
    final (pose, text) = _c.goalReached
        ? (
            'mascot_cheer',
            'Journée parfaite ! Reviens demain pour garder ta flamme.',
          )
        : current != null && !_c.isChecked(reminderHours[current])
        ? (
            'mascot_drink',
            'C\'est l\'heure ! Bois ${settings.doseLabel} puis touche '
                'l\'étape de ${formatHour(reminderHours[current])}.',
          )
        : missed.isNotEmpty
        ? (
            'mascot_sad',
            'Tu as oublié ${missed.length} rappel${missed.length > 1 ? 's' : ''}. '
                'Pas de panique, tu peux encore rattraper !',
          )
        : next == 0
        ? (
            'mascot_happy',
            'Le premier rappel est à ${formatHour(reminderHours[0])}.',
          )
        : (
            'mascot_happy',
            next == null
                ? 'Bravo ! Rendez-vous demain à ${formatHour(reminderHours[0])}.'
                : 'Bravo ! Prochain rappel à ${formatHour(reminderHours[next])}.',
          );
    return MascotSays(pose: pose, text: text, size: 96);
  }

  Widget _path(DrinkSettings settings, double width) {
    const node = 76.0;
    final amplitude = (width - node) / 2 - 24;
    return Column(
      children: [
        for (var i = 0; i < reminderHours.length; i++)
          Transform.translate(
            offset: Offset(_zigzag[i] * amplitude, 0),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: _PathNode(
                hour: reminderHours[i],
                state: _c.slotState(i),
                drinkAsset: settings.type.asset,
                onTap: () => _onTapSlot(i),
              ),
            ),
          ),
        _GoalChest(reached: _c.goalReached),
      ],
    );
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
            semanticLabel: 'Flamme : ${c.streak} jours',
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

class _DayBanner extends StatelessWidget {
  const _DayBanner({required this.controller});

  final HydrationController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final remaining = streakMinChecks - c.checkedCount;
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
            'AUJOURD\'HUI · ${c.checkedCount}/${reminderHours.length} RAPPELS',
            style: Duo.label.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Text(
            '${formatLiters(c.drunkMl)} sur ${formatLiters(c.goalMl)}',
            style: Duo.title.copyWith(color: Colors.white),
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
                      ? 'Encore $remaining rappel${remaining > 1 ? 's' : ''} '
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

class _PathNode extends StatelessWidget {
  const _PathNode({
    required this.hour,
    required this.state,
    required this.drinkAsset,
    required this.onTap,
  });

  final int hour;
  final SlotState state;
  final String drinkAsset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
        child: SvgPicture.asset(drinkAsset, width: 34, height: 34),
      ),
    };
    return Semantics(
      button: true,
      label: '${formatHour(hour)}, $status',
      excludeSemantics: true,
      child: GestureDetector(
        key: ValueKey('slot_$hour'),
        onTap: onTap,
        child: Column(
          children: [
            if (state == SlotState.current)
              Container(
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
                  style: Duo.label.copyWith(color: Duo.green, fontSize: 14),
                ),
              ),
            Container(
              width: 76,
              height: 70,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: shadow, offset: const Offset(0, 7)),
                ],
              ),
              alignment: Alignment.center,
              child: icon,
            ),
            const SizedBox(height: 10),
            Text(
              formatHour(hour),
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
    );
  }
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
