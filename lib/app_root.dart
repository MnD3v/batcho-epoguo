import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'hydration_controller.dart';
import 'screens/auth_screens.dart';
import 'screens/main_shell.dart';
import 'screens/onboarding_screen.dart';
import 'services/auth_service.dart';
import 'social_controller.dart';
import 'theme/duo.dart';

/// Choisit l'écran selon la situation : pas connecté → accueil, connecté
/// sans alertes → questionnaire, sinon → l'appli.
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
        if (user == null) {
          return WelcomeScreen(
              key: const ValueKey('welcome'), auth: widget.auth);
        }
        if (_loading) return const _Loading();
        if (!widget.controller.isSetUp) {
          return OnboardingScreen(
            key: ValueKey('onboarding_${user.uid}'),
            controller: widget.controller,
            isFirstRun: true,
            user: user,
          );
        }
        return MainShell(
          key: ValueKey('main_${user.uid}'),
          controller: widget.controller,
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
            SvgPicture.asset('assets/mascot/mascot_drink.svg', height: 150),
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
