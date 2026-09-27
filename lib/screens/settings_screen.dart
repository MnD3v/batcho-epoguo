import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/kidney_tips.dart';
import '../hydration_controller.dart';
import '../models/plan.dart';
import '../services/auth_service.dart';
import '../theme/duo.dart';
import '../widgets/duo_widgets.dart';
import 'onboarding_screen.dart';

/// Compte, alertes, déconnexion et suppression du compte.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.controller,
    required this.auth,
  });

  final HydrationController controller;
  final AuthService auth;

  void _backToStart(BuildContext context) =>
      Navigator.of(context).popUntil((r) => r.isFirst);

  Future<void> _rename(BuildContext context) async {
    final name = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (_) =>
          _RenameSheet(initial: controller.profile?.firstName ?? ''),
    );
    if (name == null) return;
    await auth.updateFirstName(name);
    await controller.renameTo(name);
  }

  Future<void> _signOut(BuildContext context) async {
    final ok = await _confirm(
      context,
      title: 'Se déconnecter ?',
      text: auth.isDemo
          ? 'Tes alertes s\'arrêtent sur ce téléphone.'
          : 'Tes alertes s\'arrêtent sur ce téléphone. Ta progression est '
              'sauvegardée : reconnecte-toi pour la retrouver.',
      action: 'Se déconnecter',
    );
    if (ok != true || !context.mounted) return;
    _backToStart(context);
    await auth.signOut();
  }

  Future<void> _delete(BuildContext context) async {
    final deleted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (_) => _DeleteSheet(auth: auth, controller: controller),
    );
    if (deleted == true && context.mounted) _backToStart(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final profile = controller.profile;
            final plan = controller.plan;
            return ListView(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 32),
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Retour',
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Duo.gray,
                        size: 30,
                      ),
                    ),
                    const Text('Paramètres', style: Duo.title),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      const Text('MON COMPTE', style: Duo.label),
                      const SizedBox(height: 10),
                      DuoCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _Row(
                              icon: Icons.person_rounded,
                              label: 'Prénom',
                              value: profile?.firstName ?? '',
                              onTap: () => _rename(context),
                            ),
                            const Divider(height: 2, thickness: 2),
                            _Row(
                              icon: Icons.mail_rounded,
                              label: 'E-mail',
                              value: profile?.email ??
                                  auth.user.value?.email ??
                                  '',
                            ),
                          ],
                        ),
                      ),
                      if (auth.isDemo) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Mode démo : ce compte reste sur ce téléphone.',
                          style: Duo.body.copyWith(
                            fontSize: 12,
                            color: Duo.gray,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      const Text('MES ALERTES', style: Duo.label),
                      const SizedBox(height: 10),
                      if (plan != null)
                        DuoCard(
                          child: Row(
                            children: [
                              SvgPicture.asset(
                                'assets/icons/drop.svg',
                                width: 36,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '${plan.rhythm.label}\n'
                                  '${plan.reminders.length} alertes · '
                                  '${formatLiters(plan.goalMl)} par jour',
                                  style: Duo.heading.copyWith(fontSize: 15),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      _SoundChoice(controller: controller),
                      const SizedBox(height: 12),
                      DuoButton(
                        label: 'Modifier mes alertes',
                        color: Duo.blue,
                        shadow: Duo.blueDark,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => OnboardingScreen(
                              controller: controller,
                              isFirstRun: false,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DuoButton.outline(
                        label: 'Faire sonner un essai',
                        icon: Icons.notifications_active_rounded,
                        onPressed: plan == null
                            ? null
                            : () async {
                                final messenger = ScaffoldMessenger.of(context);
                                await controller.scheduler.requestPermission();
                                await controller.scheduler.showTest(
                                  plan.reminders.first,
                                  profile,
                                  loud: controller.loudAlerts,
                                );
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Alerte d\'essai envoyée'),
                                  ),
                                );
                              },
                      ),
                      const SizedBox(height: 32),
                      DuoButton.outline(
                        label: 'Se déconnecter',
                        icon: Icons.logout_rounded,
                        textColor: Duo.text,
                        onPressed: () => _signOut(context),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton(
                          onPressed: () => _delete(context),
                          child: Text(
                            'SUPPRIMER MON COMPTE',
                            style: Duo.label.copyWith(color: Duo.red),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        healthDisclaimer,
                        style: TextStyle(
                          fontSize: 12,
                          color: Duo.gray,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Bois & Vis · version 1.0.0',
                        style: TextStyle(fontSize: 12, color: Duo.gray),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Son doux (par défaut) ou sonnerie de réveil.
class _SoundChoice extends StatelessWidget {
  const _SoundChoice({required this.controller});

  final HydrationController controller;

  @override
  Widget build(BuildContext context) {
    Widget option(bool loud, IconData icon, String title, String detail) {
      final selected = controller.loudAlerts == loud;
      return Expanded(
        child: DuoCard(
          selected: selected,
          padding: const EdgeInsets.all(12),
          onTap: () => controller.setLoudAlerts(loud),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: selected ? Duo.blue : Duo.gray),
              const SizedBox(height: 6),
              Text(
                title,
                style: Duo.heading.copyWith(
                  fontSize: 15,
                  color: selected ? Duo.blueDark : Duo.text,
                ),
              ),
              Text(detail, style: Duo.body.copyWith(fontSize: 12)),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        option(
          false,
          Icons.notifications_rounded,
          'Doux',
          'Son de notification',
        ),
        const SizedBox(width: 10),
        option(true, Icons.alarm_rounded, 'Fort', 'Sonne comme un réveil'),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: Duo.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Duo.body.copyWith(fontSize: 13)),
                  Text(
                    value,
                    style: Duo.heading.copyWith(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.edit_rounded, color: Duo.gray, size: 20),
          ],
        ),
      ),
    );
  }
}

Future<bool?> _confirm(
  BuildContext context, {
  required String title,
  required String text,
  required String action,
}) =>
    showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: Duo.heading, textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text(text, style: Duo.body, textAlign: TextAlign.center),
              const SizedBox(height: 18),
              DuoButton(
                label: action,
                color: Duo.blue,
                shadow: Duo.blueDark,
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

class _RenameSheet extends StatefulWidget {
  const _RenameSheet({required this.initial});

  final String initial;

  @override
  State<_RenameSheet> createState() => _RenameSheetState();
}

class _RenameSheetState extends State<_RenameSheet> {
  late final _name = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    if (_name.text.trim().isEmpty) return;
    Navigator.of(context).pop(_name.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Ton prénom', style: Duo.heading),
          const SizedBox(height: 16),
          DuoTextField(
            controller: _name,
            label: 'Prénom',
            capitalization: TextCapitalization.words,
            action: TextInputAction.done,
            onChanged: () => setState(() {}),
            onSubmitted: _save,
          ),
          const SizedBox(height: 16),
          DuoButton(
            label: 'Enregistrer',
            onPressed: _name.text.trim().isEmpty ? null : _save,
          ),
        ],
      ),
    );
  }
}

class _DeleteSheet extends StatefulWidget {
  const _DeleteSheet({required this.auth, required this.controller});

  final AuthService auth;
  final HydrationController controller;

  @override
  State<_DeleteSheet> createState() => _DeleteSheetState();
}

class _DeleteSheetState extends State<_DeleteSheet> {
  final _password = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.auth.deleteAccount(
        password: _password.text,
        beforeDelete: widget.controller.deleteCloudData,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const MascotSays(
            pose: 'mascot_sad',
            size: 80,
            text: 'Tu veux vraiment partir ? Tes XP, badges et ta flamme '
                'seront effacés pour toujours.',
          ),
          const SizedBox(height: 16),
          DuoTextField(
            controller: _password,
            label: 'Ton mot de passe, pour confirmer',
            password: true,
            action: TextInputAction.done,
            onChanged: () => setState(() => _error = null),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            ErrorBanner(_error!),
          ],
          const SizedBox(height: 16),
          DuoButton(
            label: 'Supprimer définitivement',
            color: Duo.red,
            shadow: Duo.redDark,
            onPressed: _password.text.isEmpty || _busy ? null : _delete,
          ),
          const SizedBox(height: 10),
          DuoButton.outline(
            label: 'Je reste !',
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
  }
}
