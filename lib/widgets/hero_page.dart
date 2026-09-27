import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/duo.dart';
import 'duo_widgets.dart';
import 'motion.dart';

/// Page d'événement façon Duolingo : grande illustration en haut, vague bleu
/// nuit en bas avec le titre, le texte et un gros bouton blanc.
class HeroPage extends StatelessWidget {
  const HeroPage({
    super.key,
    required this.title,
    required this.text,
    required this.button,
    required this.onPressed,
    this.badge,
    this.onClose,
    this.secondary,
  });

  /// Couleur de la vague du bas (tool/generate_opening.py).
  static const navy = Color(0xFF0B4F9C);

  final String title;
  final String text;
  final String button;
  final VoidCallback onPressed;

  /// Petite ligne dorée sous le titre (« 🔥 FLAMME DE 3 JOURS »).
  final String? badge;
  final VoidCallback? onClose;

  /// Deuxième action, en lien sous le bouton.
  final Widget? secondary;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      body: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: Color(0xFFFFF8E7)),
                // La bande fait la fête : légère danse de haut en bas.
                LoopBuilder(
                  duration: const Duration(milliseconds: 2400),
                  builder: (context, t, _) => Transform.translate(
                    offset: Offset(0, 6 * math.sin(2 * math.pi * t)),
                    child: Transform.scale(
                      scale: 1.04,
                      alignment: Alignment.bottomCenter,
                      child: SvgPicture.asset(
                        'assets/illustrations/opening_party.svg',
                        fit: BoxFit.cover,
                        alignment: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                if (onClose != null)
                  SafeArea(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        tooltip: 'Fermer',
                        onPressed: onClose,
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Duo.text,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PopIn(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: Duo.title.copyWith(
                        color: Colors.white,
                        fontSize: 26,
                      ),
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      badge!,
                      textAlign: TextAlign.center,
                      style: Duo.label.copyWith(color: Duo.gold),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    text,
                    textAlign: TextAlign.center,
                    style: Duo.body.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
                  DuoButton(
                    label: button,
                    color: Colors.white,
                    shadow: const Color(0xFFB9C7DA),
                    textColor: navy,
                    onPressed: onPressed,
                  ),
                  if (secondary != null) ...[
                    const SizedBox(height: 8),
                    secondary!,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
