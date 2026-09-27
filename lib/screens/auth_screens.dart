import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/profile.dart';
import '../services/auth_service.dart';
import '../theme/duo.dart';
import '../widgets/duo_widgets.dart';

/// Premier écran : Reno se présente, on s'inscrit ou on se connecte.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.auth, required this.onStart});

  final AuthService auth;

  /// Commencer sans compte (il sera proposé après la première gorgée).
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
          child: Column(
            children: [
              const Spacer(),
              SvgPicture.asset('assets/mascot/mascot_cheer.svg', height: 220),
              const SizedBox(height: 16),
              Text(
                'Bois & Vis',
                style: Duo.title.copyWith(fontSize: 36, color: Duo.green),
              ),
              const SizedBox(height: 10),
              const Text(
                'Bois de l\'eau, protège tes reins\net gagne des XP !',
                textAlign: TextAlign.center,
                style: Duo.body,
              ),
              const Spacer(),
              if (auth.isDemo) ...[
                const _DemoNotice(),
                const SizedBox(height: 16),
              ],
              DuoButton(label: 'Commencer', onPressed: onStart),
              const SizedBox(height: 12),
              DuoButton.outline(
                label: 'J\'ai déjà un compte',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => SignInScreen(auth: auth),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DemoNotice extends StatelessWidget {
  const _DemoNotice();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Mode démo : Firebase n\'est pas encore branché, ton compte reste sur '
      'ce téléphone.',
      textAlign: TextAlign.center,
      style: Duo.body.copyWith(fontSize: 12, color: Duo.gray),
    );
  }
}

/// Mise en page commune : retour, Reno qui parle, le formulaire, puis le
/// gros bouton en bas.
class _AuthLayout extends StatelessWidget {
  const _AuthLayout({
    required this.mascotText,
    required this.children,
    required this.button,
    this.pose = 'mascot_happy',
  });

  final String mascotText;
  final String pose;
  final List<Widget> children;
  final Widget button;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: IconButton(
                  tooltip: 'Retour',
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Duo.gray,
                    size: 30,
                  ),
                ),
              ),
            ),
            Expanded(
              child: AutofillGroup(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  children: [
                    MascotSays(pose: pose, text: mascotText),
                    const SizedBox(height: 20),
                    ...children,
                  ],
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Duo.border, width: 2)),
              ),
              padding: const EdgeInsets.all(20),
              child: button,
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkButton extends StatelessWidget {
  const _LinkButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: onPressed,
        child: Text(
          label.toUpperCase(),
          style: Duo.label.copyWith(color: Duo.blue, fontSize: 14),
        ),
      ),
    );
  }
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key, required this.auth, this.firstName});

  final AuthService auth;

  /// Prénom déjà donné au questionnaire (sans compte).
  final String? firstName;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  late final _name = TextEditingController(text: widget.firstName);
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _valid =>
      _name.text.trim().isNotEmpty &&
      isValidEmail(_email.text) &&
      _password.text.length >= minPasswordLength;

  Future<void> _submit() async {
    if (!_valid || _busy) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.auth.signUp(
        firstName: _name.text,
        email: _email.text,
        password: _password.text,
      );
      // L'écran d'accueil laisse place au questionnaire tout seul.
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    void changed() => setState(() => _error = null);
    return _AuthLayout(
      pose: 'mascot_cheer',
      mascotText: 'Crée ton compte pour garder tes XP et ta flamme !',
      button: DuoButton(
        label: _busy ? 'Un instant…' : 'Créer mon compte',
        onPressed: _valid && !_busy ? _submit : null,
      ),
      children: [
        DuoTextField(
          controller: _name,
          label: 'Prénom',
          hint: 'Ex. Awa',
          keyboard: TextInputType.name,
          capitalization: TextCapitalization.words,
          autofillHints: const [AutofillHints.givenName],
          onChanged: changed,
        ),
        const SizedBox(height: 12),
        DuoTextField(
          controller: _email,
          label: 'E-mail',
          hint: 'awa@exemple.com',
          keyboard: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          onChanged: changed,
          error: _email.text.isNotEmpty && !isValidEmail(_email.text)
              ? 'Adresse e-mail invalide'
              : null,
        ),
        const SizedBox(height: 12),
        DuoTextField(
          controller: _password,
          label: 'Mot de passe',
          hint: '$minPasswordLength caractères minimum',
          password: true,
          autofillHints: const [AutofillHints.newPassword],
          action: TextInputAction.done,
          onChanged: changed,
          onSubmitted: _submit,
          error: _password.text.isNotEmpty &&
                  _password.text.length < minPasswordLength
              ? 'Trop court : $minPasswordLength caractères minimum'
              : null,
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          ErrorBanner(_error!),
        ],
        const SizedBox(height: 12),
        _LinkButton(
          label: 'J\'ai déjà un compte',
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => SignInScreen(auth: widget.auth),
            ),
          ),
        ),
      ],
    );
  }
}

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key, required this.auth});

  final AuthService auth;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _valid => isValidEmail(_email.text) && _password.text.isNotEmpty;

  Future<void> _submit() async {
    if (!_valid || _busy) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.auth.signIn(email: _email.text, password: _password.text);
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forgotPassword() async {
    final sent = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (_) => _ResetSheet(auth: widget.auth, email: _email.text),
    );
    if (sent == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.auth.isDemo
              ? 'Mode démo : aucun e-mail n\'est envoyé.'
              : 'Lien envoyé à $sent. Regarde tes e-mails !',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    void changed() => setState(() => _error = null);
    return _AuthLayout(
      mascotText: 'Content de te revoir ! Connecte-toi.',
      button: DuoButton(
        label: _busy ? 'Un instant…' : 'Se connecter',
        onPressed: _valid && !_busy ? _submit : null,
      ),
      children: [
        DuoTextField(
          controller: _email,
          label: 'E-mail',
          keyboard: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          onChanged: changed,
        ),
        const SizedBox(height: 12),
        DuoTextField(
          controller: _password,
          label: 'Mot de passe',
          password: true,
          autofillHints: const [AutofillHints.password],
          action: TextInputAction.done,
          onChanged: changed,
          onSubmitted: _submit,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _forgotPassword,
            child: Text(
              'Mot de passe oublié ?',
              style: Duo.body.copyWith(color: Duo.blue, fontSize: 14),
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 4),
          ErrorBanner(_error!),
        ],
        const SizedBox(height: 12),
        _LinkButton(
          label: 'Créer un compte',
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => SignUpScreen(auth: widget.auth),
            ),
          ),
        ),
      ],
    );
  }
}

class _ResetSheet extends StatefulWidget {
  const _ResetSheet({required this.auth, required this.email});

  final AuthService auth;
  final String email;

  @override
  State<_ResetSheet> createState() => _ResetSheetState();
}

class _ResetSheetState extends State<_ResetSheet> {
  late final _email = TextEditingController(text: widget.email);
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.auth.sendPasswordReset(_email.text);
      if (mounted) Navigator.of(context).pop(_email.text.trim());
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
          const Text('Mot de passe oublié ?', style: Duo.heading),
          const SizedBox(height: 6),
          const Text(
            'Je t\'envoie un lien pour en choisir un nouveau.',
            style: Duo.body,
          ),
          const SizedBox(height: 16),
          DuoTextField(
            controller: _email,
            label: 'E-mail',
            keyboard: TextInputType.emailAddress,
            action: TextInputAction.send,
            onChanged: () => setState(() => _error = null),
            onSubmitted: _send,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            ErrorBanner(_error!),
          ],
          const SizedBox(height: 16),
          DuoButton(
            label: 'Envoyer le lien',
            color: Duo.blue,
            shadow: Duo.blueDark,
            onPressed: isValidEmail(_email.text) && !_busy ? _send : null,
          ),
        ],
      ),
    );
  }
}
