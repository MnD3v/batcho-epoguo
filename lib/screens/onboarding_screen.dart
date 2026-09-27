import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/kidney_tips.dart';
import '../hydration_controller.dart';
import '../models/plan.dart';
import '../models/profile.dart';
import '../services/reminder_scheduler.dart';
import '../theme/duo.dart';
import '../widgets/duo_widgets.dart';
import 'main_shell.dart';

enum _Step { welcome, identity, intake, difficulties, rhythm, amounts, ready }

/// Premier lancement : Reno pose une question par écran, puis active les
/// alertes. Depuis le profil, seules les étapes des alertes sont montrées.
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
  late final _steps = widget.isFirstRun
      ? _Step.values
      : const [_Step.rhythm, _Step.amounts, _Step.ready];
  int _index = 0;
  bool _saving = false;

  late final _name = TextEditingController(
    text: widget.controller.profile?.firstName,
  );
  late final _email = TextEditingController(
    text: widget.controller.profile?.email,
  );
  late UsualIntake? _intake = widget.controller.profile?.usualIntake;
  late final Set<Difficulty> _difficulties = {
    ...?widget.controller.profile?.difficulties,
  };
  late HydrationPlan _plan =
      widget.controller.plan ?? _regularPlan(Rhythm.every2h);

  _Step get _step => _steps[_index];

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  /// Quantité proposée pour boire environ 2 L dans la journée.
  static HydrationPlan _regularPlan(Rhythm rhythm) {
    final count = HydrationPlan.regular(rhythm, 0).reminders.length;
    final ideal = 2000 / count;
    final dose = HydrationPlan.doses.reduce(
      (a, b) => (a - ideal).abs() <= (b - ideal).abs() ? a : b,
    );
    return HydrationPlan.regular(rhythm, dose);
  }

  bool get _canContinue => switch (_step) {
        _Step.identity =>
          _name.text.trim().isNotEmpty && isValidEmail(_email.text),
        _Step.intake => _intake != null,
        _Step.amounts => _plan.reminders.isNotEmpty,
        _ => true,
      };

  void _back() {
    if (_index > 0) {
      setState(() => _index--);
    } else {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _next() async {
    FocusScope.of(context).unfocus();
    if (_step == _Step.identity || _step == _Step.difficulties) {
      await widget.controller.saveProfile(
        UserProfile(
          firstName: _name.text.trim(),
          email: _email.text.trim(),
          usualIntake: _intake ?? UsualIntake.about1_5L,
          difficulties: _difficulties,
        ),
      );
    }
    if (_index < _steps.length - 1) {
      setState(() => _index++);
      return;
    }
    setState(() => _saving = true);
    await widget.controller.savePlan(_plan);
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
    final canGoBack = _index > 0 || !widget.isFirstRun;
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
                      _index == 0
                          ? Icons.close_rounded
                          : Icons.arrow_back_rounded,
                      color: canGoBack ? Duo.gray : Colors.transparent,
                      size: 30,
                    ),
                  ),
                  Expanded(
                    child: DuoProgressBar(value: _index / (_steps.length - 1)),
                  ),
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
                      _Step.welcome => _welcome(),
                      _Step.identity => _identity(),
                      _Step.intake => _intakeStep(),
                      _Step.difficulties => _difficultiesStep(),
                      _Step.rhythm => _rhythm(),
                      _Step.amounts => _amounts(),
                      _Step.ready => _ready(),
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
                  _Step.welcome => 'C\'est parti',
                  _Step.ready when widget.isFirstRun => 'Activer mes alertes',
                  _Step.ready => 'Enregistrer',
                  _ => 'Continuer',
                },
                onPressed: _saving || !_canContinue ? null : _next,
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
          child:
              SvgPicture.asset('assets/mascot/mascot_cheer.svg', height: 210),
        ),
        const SizedBox(height: 20),
        const Text(
          'Salut ! Moi, c\'est Reno,\nton rein.',
          textAlign: TextAlign.center,
          style: Duo.title,
        ),
        const SizedBox(height: 12),
        const Text(
          'Réponds à 4 petites questions et je sonnerai quand il faut boire.',
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

  List<Widget> _identity() => [
        const MascotSays(
            text: 'Faisons connaissance ! Comment tu t\'appelles ?'),
        const SizedBox(height: 20),
        _Field(
          controller: _name,
          label: 'Prénom',
          hint: 'Ex. Awa',
          keyboard: TextInputType.name,
          capitalization: TextCapitalization.words,
          onChanged: () => setState(() {}),
        ),
        const SizedBox(height: 12),
        _Field(
          controller: _email,
          label: 'E-mail',
          hint: 'awa@exemple.com',
          keyboard: TextInputType.emailAddress,
          onChanged: () => setState(() {}),
          error: _email.text.isNotEmpty && !isValidEmail(_email.text)
              ? 'Adresse e-mail invalide'
              : null,
        ),
      ];

  List<Widget> _intakeStep() => [
        MascotSays(
          text: 'Enchanté, ${_name.text.trim()} ! Combien d\'eau bois-tu par '
              'jour, en moyenne ?',
        ),
        const SizedBox(height: 20),
        for (final intake in UsualIntake.values)
          _Choice(
            icon: intake.icon,
            label: intake.label,
            selected: intake == _intake,
            onTap: () => setState(() => _intake = intake),
          ),
      ];

  List<Widget> _difficultiesStep() => [
        const MascotSays(
          pose: 'mascot_sad',
          text:
              'Qu\'est-ce qui t\'empêche de boire ? Choisis tout ce qui compte.',
        ),
        const SizedBox(height: 20),
        for (final d in Difficulty.values)
          _Choice(
            label: d.label,
            selected: _difficulties.contains(d),
            checkbox: true,
            onTap: () => setState(() {
              if (!_difficulties.remove(d)) _difficulties.add(d);
            }),
          ),
      ];

  List<Widget> _rhythm() => [
        const MascotSays(
          pose: 'mascot_drink',
          text: 'Quand veux-tu que je sonne ?',
        ),
        const SizedBox(height: 20),
        for (final rhythm in Rhythm.values)
          _Choice(
            label: rhythm.label,
            detail: switch (rhythm) {
              Rhythm.every2h => '7h, 9h, 11h… jusqu\'à 19h',
              Rhythm.every3h => '7h, 10h, 13h, 16h, 19h',
              Rhythm.custom => 'Tu choisis les heures',
            },
            selected: rhythm == _plan.rhythm,
            onTap: () => setState(() {
              if (rhythm == _plan.rhythm) return;
              _plan = rhythm == Rhythm.custom
                  ? HydrationPlan.customExample()
                  : _regularPlan(rhythm);
            }),
          ),
      ];

  List<Widget> _amounts() => [
        MascotSays(
          pose: 'mascot_drink',
          text: _plan.rhythm == Rhythm.custom
              ? 'Choisis tes heures et combien boire à chacune.'
              : 'Combien veux-tu boire à chaque alerte ?',
        ),
        const SizedBox(height: 20),
        if (_plan.rhythm == Rhythm.custom)
          ..._customEditor()
        else ...[
          Row(
            children: [
              for (final ml in HydrationPlan.doses)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: DuoCard(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      selected: ml == _plan.commonDose,
                      onTap: () => setState(
                        () => _plan = HydrationPlan.regular(_plan.rhythm, ml),
                      ),
                      child: Text(
                        formatLiters(ml),
                        textAlign: TextAlign.center,
                        style: Duo.heading.copyWith(
                          fontSize: 16,
                          color:
                              ml == _plan.commonDose ? Duo.blueDark : Duo.text,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final r in _plan.reminders) _TimeChip(time: r.time)
            ],
          ),
        ],
        const SizedBox(height: 20),
        _GoalCard(plan: _plan),
      ];

  List<Widget> _customEditor() {
    final reminders = _plan.reminders;
    void update(List<Reminder> list) =>
        setState(() => _plan = HydrationPlan(Rhythm.custom, list));

    Future<void> pickTime(int i) async {
      final r = reminders[i];
      final picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: r.hour, minute: r.minute),
        helpText: 'Heure de l\'alerte',
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        ),
      );
      if (picked == null) return;
      final minutes = picked.hour * 60 + picked.minute;
      if (reminders.any((o) => o.minutes == minutes && o != r)) return;
      update([...reminders]..[i] = r.copyWith(minutes: minutes));
    }

    void changeDose(int i, int delta) {
      final r = reminders[i];
      final pos = HydrationPlan.doses.indexOf(r.ml) + delta;
      if (pos < 0 || pos >= HydrationPlan.doses.length) return;
      update([...reminders]..[i] = r.copyWith(ml: HydrationPlan.doses[pos]));
    }

    final last = reminders.isEmpty ? 6 * 60 : reminders.last.minutes;
    final nextMinutes = (last + 120).clamp(0, 23 * 60);
    final canAdd = reminders.length < HydrationPlan.maxReminders &&
        !reminders.any((r) => r.minutes == nextMinutes);

    return [
      for (var i = 0; i < reminders.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: DuoCard(
            padding: const EdgeInsets.fromLTRB(10, 8, 0, 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => pickTime(i),
                  child: _TimeChip(time: reminders[i].time, editable: true),
                ),
                const Spacer(),
                _SmallRound(
                  icon: Icons.remove_rounded,
                  tooltip: 'Moins',
                  onPressed: HydrationPlan.doses.first < reminders[i].ml
                      ? () => changeDose(i, -1)
                      : null,
                ),
                SizedBox(
                  width: 56,
                  child: Text(
                    formatLiters(reminders[i].ml),
                    textAlign: TextAlign.center,
                    style: Duo.heading.copyWith(fontSize: 16),
                  ),
                ),
                _SmallRound(
                  icon: Icons.add_rounded,
                  tooltip: 'Plus',
                  onPressed: reminders[i].ml < HydrationPlan.doses.last
                      ? () => changeDose(i, 1)
                      : null,
                ),
                IconButton(
                  tooltip: 'Supprimer',
                  visualDensity: VisualDensity.compact,
                  onPressed: reminders.length > 1
                      ? () => update([...reminders]..removeAt(i))
                      : null,
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: Duo.gray,
                ),
              ],
            ),
          ),
        ),
      DuoButton.outline(
        label: 'Ajouter une heure',
        icon: Icons.add_alarm_rounded,
        onPressed: canAdd
            ? () => update([
                  ...reminders,
                  Reminder(nextMinutes, reminders.lastOrNull?.ml ?? 500),
                ])
            : null,
      ),
    ];
  }

  List<Widget> _ready() {
    final name = widget.controller.profile?.firstName ?? _name.text.trim();
    return [
      MascotSays(
        pose: 'mascot_cheer',
        text: widget.isFirstRun
            ? 'Tout est prêt, $name ! Je vais sonner à chacune de tes alertes.'
            : 'C\'est noté ! Voici tes nouvelles alertes.',
      ),
      const SizedBox(height: 20),
      _GoalCard(plan: _plan),
      const SizedBox(height: 16),
      DuoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('À chaque alerte', style: Duo.heading),
            const SizedBox(height: 8),
            Text(
              '« ${alertTitle(widget.controller.profile)} »\n$kidneyPriceMessage',
              style: Duo.body.copyWith(fontSize: 15),
            ),
          ],
        ),
      ),
      if (_difficulties.isNotEmpty) ...[
        const SizedBox(height: 16),
        DuoCard(
          color: Duo.blueLight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MES CONSEILS POUR TOI',
                style: Duo.label.copyWith(color: Duo.blueDark),
              ),
              for (final d in _difficulties)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '• ${d.advice}',
                    style: Duo.body.copyWith(fontSize: 15, color: Duo.text),
                  ),
                ),
            ],
          ),
        ),
      ],
    ];
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.plan});

  final HydrationPlan plan;

  @override
  Widget build(BuildContext context) {
    final goal = plan.goalMl;
    final advice = goal > 3000
        ? 'C\'est beaucoup ! Pour la plupart des adultes, 1,5 à 2 L par jour '
            'suffisent (un peu plus quand il fait chaud).'
        : goal < 1500
            ? 'C\'est un peu juste : vise au moins 1,5 L par jour.'
            : 'Parfait, c\'est un bon objectif !';
    return DuoCard(
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
            '${formatLiters(goal)} en ${plan.reminders.length} alerte'
            '${plan.reminders.length > 1 ? 's' : ''}',
            style: Duo.title.copyWith(color: Duo.blueDark),
          ),
          const SizedBox(height: 6),
          Text(advice, style: Duo.body.copyWith(fontSize: 14)),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.keyboard,
    required this.onChanged,
    this.capitalization = TextCapitalization.none,
    this.error,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType keyboard;
  final VoidCallback onChanged;
  final TextCapitalization capitalization;
  final String? error;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color, width: 2),
        );
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      textCapitalization: capitalization,
      autocorrect: false,
      onChanged: (_) => onChanged(),
      style: Duo.heading.copyWith(fontSize: 17),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: error,
        filled: true,
        fillColor: Duo.snow,
        labelStyle: Duo.body,
        hintStyle: Duo.body.copyWith(color: Duo.gray),
        border: border(Duo.border),
        enabledBorder: border(Duo.border),
        focusedBorder: border(Duo.blue),
        errorBorder: border(Duo.red),
        focusedErrorBorder: border(Duo.red),
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.detail,
    this.checkbox = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? icon;
  final String? detail;
  final bool checkbox;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DuoCard(
        selected: selected,
        onTap: onTap,
        child: Row(
          children: [
            if (icon != null) ...[
              SvgPicture.asset(icon!, width: 44, height: 44),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Duo.heading.copyWith(
                      fontSize: 17,
                      color: selected ? Duo.blueDark : Duo.text,
                    ),
                  ),
                  if (detail != null)
                    Text(detail!, style: Duo.body.copyWith(fontSize: 14)),
                ],
              ),
            ),
            if (checkbox)
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: selected ? Duo.blue : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected ? Duo.blue : Duo.border,
                    width: 2,
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 20,
                      )
                    : null,
              ),
          ],
        ),
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.time, this.editable = false});

  final String time;
  final bool editable;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: editable ? Duo.blueLight : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: editable ? Duo.blue : Duo.border, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.alarm_rounded, color: Duo.blue, size: 20),
          const SizedBox(width: 6),
          Text(
            time,
            style: Duo.heading.copyWith(
              fontSize: 16,
              color: editable ? Duo.blueDark : Duo.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallRound extends StatelessWidget {
  const _SmallRound({
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
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: enabled ? Duo.blue : Duo.border,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: enabled ? Duo.blueDark : Duo.border,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: enabled ? Colors.white : Duo.gray, size: 22),
        ),
      ),
    );
  }
}
