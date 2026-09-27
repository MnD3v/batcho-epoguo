import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/kidney_tips.dart';
import '../data/reminders.dart';
import '../hydration_controller.dart';
import '../models/drink.dart';
import '../theme/duo.dart';
import '../widgets/duo_widgets.dart';
import 'main_shell.dart';

/// Premier lancement (ou modification) : la mascotte pose les questions une
/// par une, comme une leçon.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.controller,
    required this.isFirstRun,
  });

  final HydrationController controller;
  final bool isFirstRun;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _maxUnits = 4;

  late DrinkSettings _draft =
      widget.controller.settings ?? DrinkSettings.defaults(DrinkType.pureWater);
  late int _step = widget.isFirstRun ? 0 : 1;
  bool _saving = false;

  static const _lastStep = 3;

  void _back() {
    if (_step > (widget.isFirstRun ? 0 : 1)) {
      setState(() => _step--);
    } else {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _next() async {
    if (_step < _lastStep) {
      setState(() => _step++);
      return;
    }
    setState(() => _saving = true);
    await widget.controller.saveSettings(_draft);
    if (!mounted) return;
    if (widget.isFirstRun) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => MainShell(controller: widget.controller),
        ),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final canGoBack = _step > 0 || !widget.isFirstRun;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Retour',
                    onPressed: canGoBack ? _back : null,
                    icon: Icon(
                      _step == 1 && !widget.isFirstRun
                          ? Icons.close_rounded
                          : Icons.arrow_back_rounded,
                      color: canGoBack ? Duo.gray : Colors.transparent,
                      size: 30,
                    ),
                  ),
                  Expanded(child: DuoProgressBar(value: _step / _lastStep)),
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0.08, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(
                  key: ValueKey(_step),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    children: switch (_step) {
                      0 => _welcome(),
                      1 => _drinkChoice(),
                      2 => _quantity(),
                      _ => _reminders(),
                    },
                  ),
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Duo.border, width: 2)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: DuoButton(
                label: switch (_step) {
                  0 => 'C\'est parti',
                  _lastStep when widget.isFirstRun => 'Activer les rappels',
                  _lastStep => 'Enregistrer',
                  _ => 'Continuer',
                },
                onPressed: _saving ? null : _next,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _welcome() => [
    const SizedBox(height: 12),
    Center(
      child: SvgPicture.asset('assets/mascot/mascot_cheer.svg', height: 210),
    ),
    const SizedBox(height: 20),
    const Text(
      'Salut ! Moi, c\'est Reno,\nton rein.',
      textAlign: TextAlign.center,
      style: Duo.title,
    ),
    const SizedBox(height: 12),
    const Text(
      'Je filtre ton sang jour et nuit. Pour rester en forme, j\'ai besoin '
      'd\'eau : bois toutes les 2 heures, de 7h à 20h, et gagne des XP !',
      textAlign: TextAlign.center,
      style: Duo.body,
    ),
    const SizedBox(height: 24),
    const Text(
      healthDisclaimer,
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 12, color: Duo.gray, height: 1.4),
    ),
  ];

  List<Widget> _drinkChoice() => [
    const MascotSays(text: 'Qu\'est-ce que tu bois d\'habitude ?'),
    const SizedBox(height: 20),
    for (final type in DrinkType.values)
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: DuoCard(
          selected: type == _draft.type,
          onTap: () => setState(() {
            if (type != _draft.type) _draft = DrinkSettings.defaults(type);
          }),
          child: Row(
            children: [
              SvgPicture.asset(type.asset, width: 52, height: 52),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  type.label,
                  style: Duo.heading.copyWith(
                    color: type == _draft.type ? Duo.blueDark : Duo.text,
                  ),
                ),
              ),
              Text(
                type.sizesMl.length == 1
                    ? formatLiters(type.sizesMl.first)
                    : '${type.sizesMl.first}–${type.sizesMl.last} ml',
                style: Duo.body.copyWith(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
  ];

  List<Widget> _quantity() {
    final type = _draft.type;
    final goal = _draft.doseMl * reminderHours.length;
    final advice = goal > 3000
        ? 'C\'est beaucoup ! Pour la plupart des adultes, 1,5 à 2 L par jour '
              'suffisent (un peu plus quand il fait chaud).'
        : goal < 1500
        ? 'C\'est un peu juste : vise au moins 1,5 L par jour.'
        : 'Parfait, c\'est un bon objectif !';
    return [
      MascotSays(
        pose: 'mascot_drink',
        text: 'Combien de ${type.plural} à chaque rappel ?',
      ),
      const SizedBox(height: 20),
      if (type.sizesMl.length > 1) ...[
        Text('CONTENANCE', style: Duo.label),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final ml in type.sizesMl)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: DuoCard(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    selected: ml == _draft.unitMl,
                    onTap: () =>
                        setState(() => _draft = _draft.copyWith(unitMl: ml)),
                    child: Text(
                      ml >= 1000 ? formatLiters(ml) : '$ml ml',
                      textAlign: TextAlign.center,
                      style: Duo.heading.copyWith(
                        fontSize: 15,
                        color: ml == _draft.unitMl ? Duo.blueDark : Duo.text,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
      ],
      Text('À CHAQUE RAPPEL', style: Duo.label),
      const SizedBox(height: 10),
      DuoCard(
        child: Row(
          children: [
            _RoundButton(
              icon: Icons.remove_rounded,
              tooltip: 'Moins',
              onPressed: _draft.unitsPerReminder > 1
                  ? () => setState(
                      () => _draft = _draft.copyWith(
                        unitsPerReminder: _draft.unitsPerReminder - 1,
                      ),
                    )
                  : null,
            ),
            Expanded(
              child: Column(
                children: [
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      for (var i = 0; i < _draft.unitsPerReminder; i++)
                        SvgPicture.asset(type.asset, width: 40, height: 40),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(type.units(_draft.unitsPerReminder), style: Duo.heading),
                ],
              ),
            ),
            _RoundButton(
              icon: Icons.add_rounded,
              tooltip: 'Plus',
              onPressed: _draft.unitsPerReminder < _maxUnits
                  ? () => setState(
                      () => _draft = _draft.copyWith(
                        unitsPerReminder: _draft.unitsPerReminder + 1,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      DuoCard(
        color: Duo.blueLight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'OBJECTIF DU JOUR',
              style: Duo.label.copyWith(color: Duo.blueDark),
            ),
            const SizedBox(height: 4),
            Text(
              '${reminderHours.length} × ${formatLiters(_draft.doseMl)} = '
              '${formatLiters(goal)}',
              style: Duo.title.copyWith(color: Duo.blueDark),
            ),
            const SizedBox(height: 6),
            Text(advice, style: Duo.body.copyWith(fontSize: 14)),
          ],
        ),
      ),
    ];
  }

  List<Widget> _reminders() => [
    MascotSays(
      pose: 'mascot_cheer',
      text: widget.isFirstRun
          ? 'Je te préviens à chaque rappel. Active les notifications pour '
                'ne rien rater !'
          : 'C\'est noté ! Voici tes rappels.',
    ),
    const SizedBox(height: 20),
    Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final hour in reminderHours)
          DuoCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.alarm_rounded, color: Duo.blue, size: 20),
                const SizedBox(width: 6),
                Text(
                  formatHour(hour),
                  style: Duo.heading.copyWith(fontSize: 16),
                ),
              ],
            ),
          ),
      ],
    ),
    const SizedBox(height: 20),
    DuoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Comment gagner des XP', style: Duo.heading),
          const SizedBox(height: 10),
          _rule('assets/icons/xp.svg', '+10 XP par rappel coché'),
          _rule('assets/icons/star.svg', '+30 XP pour une journée parfaite'),
          _rule(
            'assets/icons/flame.svg',
            'Coche au moins 5 rappels par jour pour garder ta flamme',
          ),
          _rule('assets/icons/book.svg', '+5 XP par leçon lue'),
        ],
      ),
    ),
  ];

  Widget _rule(String icon, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        SvgPicture.asset(icon, width: 26, height: 26),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: Duo.body.copyWith(fontSize: 15))),
      ],
    ),
  );
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: enabled ? Duo.blue : Duo.border,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: enabled ? Duo.blueDark : Duo.border,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: enabled ? Colors.white : Duo.gray, size: 28),
        ),
      ),
    );
  }
}
