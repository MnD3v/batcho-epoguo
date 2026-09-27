import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/duo.dart';

/// Bouton en relief qui s'enfonce quand on appuie dessus.
class DuoButton extends StatefulWidget {
  const DuoButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = Duo.green,
    this.shadow = Duo.greenDark,
    this.textColor = Colors.white,
    this.borderColor,
    this.icon,
  });

  /// Variante blanche avec bordure grise.
  const DuoButton.outline({
    super.key,
    required this.label,
    required this.onPressed,
    this.textColor = Duo.blue,
    this.icon,
  })  : color = Colors.white,
        shadow = Duo.border,
        borderColor = Duo.border;

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color shadow;
  final Color textColor;
  final Color? borderColor;
  final IconData? icon;

  @override
  State<DuoButton> createState() => _DuoButtonState();
}

class _DuoButtonState extends State<DuoButton> {
  static const _depth = 4.0;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final color = enabled ? widget.color : Duo.border;
    final shadow = enabled ? widget.shadow : Duo.border;
    final textColor = enabled ? widget.textColor : Duo.gray;
    final offset = _down ? _depth : 0.0;
    return Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: () => setState(() => _down = false),
        onTapUp: enabled
            ? (_) {
                setState(() => _down = false);
                HapticFeedback.lightImpact();
                widget.onPressed!();
              }
            : null,
        child: Padding(
          padding: EdgeInsets.only(top: offset),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
              border: widget.borderColor != null
                  ? Border.all(color: widget.borderColor!, width: 2)
                  : null,
              boxShadow: [
                BoxShadow(color: shadow, offset: Offset(0, _depth - offset)),
              ],
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: textColor, size: 22),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      widget.label.toUpperCase(),
                      style: TextStyle(
                        fontFamily: Duo.font,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Carte à bordure grise épaisse en bas ; bleue quand elle est choisie.
class DuoCard extends StatelessWidget {
  const DuoCard({
    super.key,
    required this.child,
    this.onTap,
    this.selected = false,
    this.padding = const EdgeInsets.all(16),
    this.color,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool selected;
  final EdgeInsets padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? Duo.blue : Duo.border;
    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? (selected ? Duo.blueLight : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border(
          top: BorderSide(color: borderColor, width: 2),
          left: BorderSide(color: borderColor, width: 2),
          right: BorderSide(color: borderColor, width: 2),
          bottom: BorderSide(color: borderColor, width: 4),
        ),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap!();
      },
      child: card,
    );
  }
}

/// Barre de progression arrondie avec reflet.
class DuoProgressBar extends StatelessWidget {
  const DuoProgressBar({
    super.key,
    required this.value,
    this.color = Duo.green,
    this.height = 16,
    this.track = Duo.border,
  });

  final double value;
  final Color color;
  final double height;
  final Color track;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Container(
        height: height,
        color: track,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: value.clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          builder: (context, v, _) => FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: v,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(height),
              ),
              alignment: Alignment.topCenter,
              padding: EdgeInsets.fromLTRB(
                height / 2,
                height * 0.22,
                height / 2,
                0,
              ),
              child: v > 0.08
                  ? Container(
                      height: height * 0.25,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(height),
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

/// Icône SVG suivie d'un nombre, comme dans la barre du haut.
class StatChip extends StatelessWidget {
  const StatChip({
    super.key,
    required this.icon,
    required this.value,
    required this.color,
    this.semanticLabel,
  });

  final String icon;
  final String value;
  final Color color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      excludeSemantics: semanticLabel != null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(icon, width: 28, height: 28),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: Duo.font,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// La mascotte Reno qui parle dans une bulle.
class MascotSays extends StatelessWidget {
  const MascotSays({
    super.key,
    required this.text,
    this.pose = 'mascot_happy',
    this.size = 110,
  });

  final String text;
  final String pose;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SvgPicture.asset('assets/mascot/$pose.svg', width: size, height: size),
        Expanded(child: SpeechBubble(text: text)),
      ],
    );
  }
}

class SpeechBubble extends StatelessWidget {
  const SpeechBubble({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BubblePainter(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(26, 14, 16, 14),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: Duo.font,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Duo.text,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const tail = 10.0;
    final rect = RRect.fromLTRBR(
      tail,
      0,
      size.width,
      size.height,
      const Radius.circular(16),
    );
    final mid = size.height / 2;
    final path = Path()
      ..addRRect(rect)
      ..moveTo(tail + 1, mid - 9)
      ..lineTo(0, mid)
      ..lineTo(tail + 1, mid + 9)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.white);
    final outline = Path.combine(
      PathOperation.union,
      Path()..addRRect(rect),
      Path()
        ..moveTo(tail + 1, mid - 9)
        ..lineTo(0, mid)
        ..lineTo(tail + 1, mid + 9)
        ..close(),
    );
    canvas.drawPath(
      outline,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Duo.border,
    );
  }

  @override
  bool shouldRepaint(_BubblePainter old) => false;
}

/// Champ de saisie arrondi ; pour un mot de passe, un œil pour l'afficher.
class DuoTextField extends StatefulWidget {
  const DuoTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.keyboard = TextInputType.text,
    this.capitalization = TextCapitalization.none,
    this.password = false,
    this.error,
    this.onChanged,
    this.onSubmitted,
    this.autofillHints,
    this.action = TextInputAction.next,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType keyboard;
  final TextCapitalization capitalization;
  final bool password;
  final String? error;
  final VoidCallback? onChanged;
  final VoidCallback? onSubmitted;
  final Iterable<String>? autofillHints;
  final TextInputAction action;

  @override
  State<DuoTextField> createState() => _DuoTextFieldState();
}

class _DuoTextFieldState extends State<DuoTextField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color, width: 2),
        );
    return TextField(
      controller: widget.controller,
      keyboardType: widget.keyboard,
      textCapitalization: widget.capitalization,
      obscureText: widget.password && _hidden,
      autocorrect: false,
      enableSuggestions: !widget.password,
      autofillHints: widget.autofillHints,
      textInputAction: widget.action,
      onChanged: (_) => widget.onChanged?.call(),
      onSubmitted: (_) => widget.onSubmitted?.call(),
      style: Duo.heading.copyWith(fontSize: 17),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        errorText: widget.error,
        filled: true,
        fillColor: Duo.snow,
        labelStyle: Duo.body,
        hintStyle: Duo.body.copyWith(color: Duo.gray),
        border: border(Duo.border),
        enabledBorder: border(Duo.border),
        focusedBorder: border(Duo.blue),
        errorBorder: border(Duo.red),
        focusedErrorBorder: border(Duo.red),
        suffixIcon: widget.password
            ? IconButton(
                tooltip: _hidden
                    ? 'Afficher le mot de passe'
                    : 'Cacher le mot de passe',
                onPressed: () => setState(() => _hidden = !_hidden),
                icon: Icon(
                  _hidden
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  color: Duo.gray,
                ),
              )
            : null,
      ),
    );
  }
}

/// Message d'erreur rouge, façon « mauvaise réponse ».
class ErrorBanner extends StatelessWidget {
  const ErrorBanner(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Duo.redLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Duo.red, width: 2),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_rounded, color: Duo.redDark),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Duo.body.copyWith(color: Duo.redDark, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
