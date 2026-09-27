import 'package:flutter/material.dart';

import '../hydration_controller.dart';
import '../screens/auth_screens.dart';
import '../services/auth_service.dart';
import '../theme/duo.dart';
import 'duo_widgets.dart';

void _openSignUp(
  BuildContext context,
  AuthService auth,
  HydrationController c,
) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            SignUpScreen(auth: auth, firstName: c.profile?.firstName),
      ),
    );

void _openSignIn(BuildContext context, AuthService auth) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => SignInScreen(auth: auth)),
    );

/// Après la première gorgée sans compte : « ne perds pas tes XP ».
Future<void> maybePromptAccount(
  BuildContext context,
  AuthService auth,
  HydrationController c,
) async {
  if (!c.shouldPromptAccount) return;
  await c.markAccountPromptShown();
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MascotSays(
              pose: 'mascot_cheer',
              size: 90,
              text: 'Bravo ${c.profile?.firstName ?? ''} ! Crée ton compte '
                  'pour ne pas perdre tes ${c.xp} XP et ta flamme.',
            ),
            const SizedBox(height: 18),
            DuoButton(
              label: 'Créer mon compte',
              onPressed: () {
                Navigator.of(sheet).pop();
                _openSignUp(context, auth, c);
              },
            ),
            const SizedBox(height: 10),
            DuoButton.outline(
              label: 'Plus tard',
              onPressed: () => Navigator.of(sheet).pop(),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Carte « Sauvegarde ta progression » pour qui n'a pas encore de compte.
class AccountCta extends StatelessWidget {
  const AccountCta({
    super.key,
    required this.auth,
    required this.controller,
    this.text = 'Crée ton compte pour sauvegarder tes XP et ta flamme, et '
        'les retrouver sur un autre téléphone.',
  });

  final AuthService auth;
  final HydrationController controller;
  final String text;

  @override
  Widget build(BuildContext context) {
    return DuoCard(
      color: Duo.greenLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            text,
            style: Duo.heading.copyWith(fontSize: 15, color: Duo.greenDark),
          ),
          const SizedBox(height: 12),
          DuoButton(
            label: 'Créer mon compte',
            onPressed: () => _openSignUp(context, auth, controller),
          ),
          const SizedBox(height: 8),
          DuoButton.outline(
            label: 'J\'ai déjà un compte',
            onPressed: () => _openSignIn(context, auth),
          ),
        ],
      ),
    );
  }
}
