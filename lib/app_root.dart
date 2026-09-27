import 'package:flutter/material.dart';

import 'hydration_controller.dart';
import 'screens/auth_screens.dart';
import 'screens/main_shell.dart';
import 'screens/onboarding_screen.dart';
import 'services/auth_service.dart';
import 'social_controller.dart';
import 'theme/duo.dart';
import 'widgets/motion.dart';

/// Choisit l'écran selon la situation : premier lancement → accueil, pas
/// encore d'alertes → questionnaire, sinon → l'appli. On peut commencer sans
/// compte : le compte est proposé après la première gorgée.
class AppRoot extends StatefulWidget {
  const AppRoot({
    super.key,
    required this.auth,
    required this.controller,
    required this.social,
  });

  final AuthService auth;
  final HydrationController controller;
  final SocialController social;

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  /// Compte dont les données sont chargées ; null si personne.
  String? _loadedUid;
  bool _loading = false;

  /// « Commencer » touché sans compte (questionnaire en cours).
  bool _guest = false;

  @override
  void initState() {
    super.initState();
    widget.auth.user.addListener(_onUserChanged);
    _onUserChanged();
  }

  @override
  void dispose() {
    widget.auth.user.removeListener(_onUserChanged);
    super.dispose();
  }

  Future<void> _onUserChanged() async {
    final user = widget.auth.user.value;
    if (user?.uid == _loadedUid) {
      // Même compte (ex. prénom modifié) : rien à recharger.
      if (user != null) await widget.controller.onSignedIn(user);
      return;
    }
    _loadedUid = user?.uid;
    setState(() => _loading = true);
    if (user == null) {
      // Déconnexion : le téléphone oublie tout, retour à l'accueil.
      _guest = false;
      await widget.controller.onSignedOut();
      widget.social.reset();
    } else {
      await widget.controller.onSignedIn(user);
      // Amis invités, défis : en arrière-plan.
      widget.social.refresh(credit: false);
    }
    if (mounted && _loadedUid == user?.uid) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.auth.user, widget.controller]),
      builder: (context, _) {
        final user = widget.auth.user.value;
        final c = widget.controller;
        if (user == null && !_guest && !c.isSetUp) {
          return WelcomeScreen(
            key: const ValueKey('welcome'),
            auth: widget.auth,
            onStart: () => setState(() => _guest = true),
          );
        }
        if (_loading) return const _Loading();
        final who = user?.uid ?? 'invite';
        if (!c.isSetUp) {
          return OnboardingScreen(
            key: ValueKey('onboarding_$who'),
            controller: c,
            isFirstRun: true,
            user: user,
          );
        }
        return MainShell(
          key: ValueKey('main_$who'),
          controller: c,
          auth: widget.auth,
          social: widget.social,
        );
      },
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AnimatedMascot(pose: 'mascot_drink', size: 150),
            const SizedBox(height: 20),
            const SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                color: Duo.green,
                backgroundColor: Duo.border,
                minHeight: 10,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Je récupère ta progression…', style: Duo.body),
          ],
        ),
      ),
    );
  }
}
