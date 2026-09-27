import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/kidney_tips.dart';
import '../hydration_controller.dart';
import '../models/city.dart';
import '../models/plan.dart';
import '../theme/duo.dart';
import '../services/auth_service.dart';
import '../widgets/account_prompt.dart';
import '../widgets/duo_widgets.dart';
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
            content: Text('Cette alerte s\'ouvre à ${reminder.time} 🔒'),
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
    return Column(
      children: [
        for (var i = 0; i < reminders.length; i++)
          Transform.translate(
            offset: Offset(_zigzag[i % _zigzag.length] * amplitude, 0),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: _PathNode(
                reminder: reminders[i],
                state: _c.slotState(i),
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

/// Mode chaleur : conseil du jour s'il fait très chaud, sinon invitation à
/// choisir sa ville.
class _HeatCard extends StatelessWidget {
  const _HeatCard({required this.controller});

  final HydrationController controller;

  @override
  Widget build(BuildContext context) {
    final city = controller.city;
    final max = controller.todayMax;
    if (city != null && !controller.isHotToday) return const SizedBox.shrink();
    final text = city == null
        ? 'Mode chaleur : choisis ta ville et je te préviens les jours de '
            'grosse chaleur.'
        : 'Il fera ${max!.round()} °C à ${city.name} aujourd\'hui : bois '
            '$hotDayExtraGlasses verres de plus !';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DuoCard(
        color: city == null ? Colors.white : const Color(0xFFFFF3E0),
        onTap: city == null ? () => pickCity(context, controller) : null,
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
                  color: city == null ? Duo.text : Duo.orangeDark,
                ),
              ),
            ),
            if (city == null)
              const Icon(Icons.chevron_right_rounded, color: Duo.gray)
            else
              SpeakButton(text: text, color: Duo.orangeDark),
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

class _PathNode extends StatelessWidget {
  const _PathNode({
    required this.reminder,
    required this.state,
    required this.onTap,
  });

  final Reminder reminder;
  final SlotState state;
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
          child: SvgPicture.asset(
            'assets/drinks/glass.svg',
            width: 34,
            height: 34,
          ),
        ),
    };
    return Semantics(
      button: true,
      label: '${reminder.time}, $status',
      excludeSemantics: true,
      child: GestureDetector(
        key: ValueKey('slot_${reminder.time}'),
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
