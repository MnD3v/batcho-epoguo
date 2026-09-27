import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/duo.dart';

/// Réglage global des animations en boucle (Reno qui respire, pulsations…).
abstract final class Motion {
  /// Coupé dans les tests (voir test/flutter_test_config.dart).
  static bool loops = true;

  /// Faux si le téléphone demande de réduire les animations.
  static bool enabled(BuildContext context) =>
      loops && !(MediaQuery.maybeOf(context)?.disableAnimations ?? false);
}

/// Anime [builder] en boucle de 0 à 1 (immobile à 0 si les boucles sont
/// coupées).
class LoopBuilder extends StatefulWidget {
  const LoopBuilder({
    super.key,
    required this.duration,
    required this.builder,
    this.child,
  });

  final Duration duration;
  final Widget Function(BuildContext context, double t, Widget? child) builder;
  final Widget? child;

  @override
  State<LoopBuilder> createState() => _LoopBuilderState();
}

class _LoopBuilderState extends State<LoopBuilder>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.enabled(context)) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        child: widget.child,
        builder: (context, child) =>
            widget.builder(context, _controller.value, child),
      );
}

enum MascotMood { idle, cheer, sad }

MascotMood moodOf(String pose) => switch (pose) {
      'mascot_cheer' => MascotMood.cheer,
      'mascot_sad' => MascotMood.sad,
      _ => MascotMood.idle,
    };

/// Reno vivant : il respire, saute de joie ou se balance, apparaît avec un
/// petit rebond et sursaute quand on le touche.
class AnimatedMascot extends StatefulWidget {
  const AnimatedMascot({
    super.key,
    required this.pose,
    required this.size,
    this.onTap,
  });

  /// Nom du fichier dans assets/mascot (ex. « mascot_cheer »).
  final String pose;
  final double size;
  final VoidCallback? onTap;

  @override
  State<AnimatedMascot> createState() => _AnimatedMascotState();
}

class _AnimatedMascotState extends State<AnimatedMascot>
    with SingleTickerProviderStateMixin {
  late final _jump = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 550),
  );

  @override
  void dispose() {
    _jump.dispose();
    super.dispose();
  }

  void _tap() {
    HapticFeedback.lightImpact();
    _jump.forward(from: 0);
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    if (size <= 0) return const SizedBox.shrink();
    final mood = moodOf(widget.pose);
    final picture = SvgPicture.asset(
      'assets/mascot/${widget.pose}.svg',
      width: size,
      height: size,
    );
    return GestureDetector(
      onTap: _tap,
      child: TweenAnimationBuilder<double>(
        // Petit rebond d'apparition (et à chaque changement de pose).
        key: ValueKey(widget.pose),
        tween: Tween(begin: 0.6, end: 1),
        duration: const Duration(milliseconds: 650),
        curve: Curves.elasticOut,
        builder: (context, appear, child) =>
            Transform.scale(scale: appear, child: child),
        child: LoopBuilder(
          duration: switch (mood) {
            MascotMood.cheer => const Duration(milliseconds: 1100),
            MascotMood.sad => const Duration(milliseconds: 3600),
            MascotMood.idle => const Duration(milliseconds: 2600),
          },
          child: picture,
          builder: (context, t, child) {
            final wave = math.sin(2 * math.pi * t);
            final (dy, angle, squash) = switch (mood) {
              // Deux petits sauts de joie.
              MascotMood.cheer => (
                  -(math.sin(2 * math.pi * t).abs()) * size * 0.1,
                  wave * 0.05,
                  1 - math.cos(4 * math.pi * t).abs() * 0.04,
                ),
              MascotMood.sad => (size * 0.015 * wave, wave * 0.045, 1.0),
              // Respiration tranquille.
              MascotMood.idle => (size * 0.03 * wave, wave * 0.025, 1.0),
            };
            return AnimatedBuilder(
              animation: _jump,
              child: child,
              builder: (context, child) {
                final jump = math.sin(math.pi * _jump.value);
                return Transform.translate(
                  offset: Offset(0, dy - jump * size * 0.18),
                  child: Transform.rotate(
                    angle: angle + jump * 0.12,
                    child: Transform.scale(
                      scaleX: 2 - squash,
                      scaleY: squash,
                      alignment: Alignment.bottomCenter,
                      child: child,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Bat doucement (étape en cours du parcours).
class Pulse extends StatelessWidget {
  const Pulse({super.key, required this.child, this.amount = 0.07});

  final Widget child;
  final double amount;

  @override
  Widget build(BuildContext context) => LoopBuilder(
        duration: const Duration(milliseconds: 1400),
        child: child,
        builder: (context, t, child) => Transform.scale(
          scale: 1 + amount * (0.5 - 0.5 * math.cos(2 * math.pi * t)),
          child: child,
        ),
      );
}

/// La flamme vacille.
class Flicker extends StatelessWidget {
  const Flicker({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => LoopBuilder(
        duration: const Duration(milliseconds: 900),
        child: child,
        builder: (context, t, child) => Transform.rotate(
          angle: math.sin(2 * math.pi * t) * 0.06,
          child: Transform.scale(
            scaleY: 1 + 0.08 * math.sin(4 * math.pi * t).abs(),
            alignment: Alignment.bottomCenter,
            child: child,
          ),
        ),
      );
}

/// Apparition avec rebond, rejouée quand [key] change.
class PopIn extends StatelessWidget {
  const PopIn({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.3, end: 1),
        duration: const Duration(milliseconds: 600),
        curve: Curves.elasticOut,
        builder: (context, v, child) => Transform.scale(scale: v, child: child),
        child: child,
      );
}

/// Nombre qui défile jusqu'à [value] (« +10 XP »).
class CountUp extends StatelessWidget {
  const CountUp({
    super.key,
    required this.value,
    required this.style,
    this.prefix = '',
    this.suffix = '',
  });

  final int value;
  final TextStyle style;
  final String prefix;
  final String suffix;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<int>(
        tween: IntTween(begin: 0, end: value),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => Text('$prefix$v$suffix', style: style),
      );
}

/// Verre qui se remplit, avec une vague et des bulles.
class GlassFill extends StatelessWidget {
  const GlassFill({
    super.key,
    required this.level,
    this.from = 0,
    this.size = 64,
    this.duration = const Duration(milliseconds: 1100),
  });

  /// Niveau d'eau, de 0 (vide) à 1 (plein).
  final double level;
  final double from;
  final double size;
  final Duration duration;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size * 0.8,
        height: size,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: from, end: level.clamp(0.0, 1.0)),
          duration: duration,
          curve: Curves.easeOutCubic,
          builder: (context, fill, _) => LoopBuilder(
            duration: const Duration(milliseconds: 1800),
            builder: (context, t, _) => CustomPaint(
              painter: _GlassPainter(fill: fill, t: t),
            ),
          ),
        ),
      );
}

class _GlassPainter extends CustomPainter {
  _GlassPainter({required this.fill, required this.t});

  final double fill;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final inset = w * 0.12;
    final glass = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w - inset, h)
      ..lineTo(inset, h)
      ..close();

    canvas.drawPath(glass, Paint()..color = const Color(0x33DDF4FF));
    canvas.save();
    canvas.clipPath(glass);
    if (fill > 0) {
      final top = h * (1 - fill);
      final amplitude = fill >= 0.98 ? h * 0.01 : h * 0.035;
      final water = Path()..moveTo(0, top);
      for (var x = 0.0; x <= w; x += 2) {
        water.lineTo(
          x,
          top + math.sin((x / w + t) * 2 * math.pi) * amplitude,
        );
      }
      water
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close();
      canvas.drawPath(
        water,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF7FD6FB), Duo.blue],
          ).createShader(Offset.zero & size),
      );
      // Bulles qui montent.
      final bubble = Paint()..color = Colors.white.withValues(alpha: 0.7);
      for (var i = 0; i < 3; i++) {
        final phase = (t + i / 3) % 1;
        final y = h - phase * (h - top);
        if (y > top + 4) {
          canvas.drawCircle(
            Offset(w * (0.3 + 0.2 * i), y),
            w * (0.035 + 0.01 * i),
            bubble,
          );
        }
      }
    }
    canvas.restore();
    // Reflet et contour.
    canvas.drawLine(
      Offset(w * 0.2, h * 0.12),
      Offset(w * 0.26, h * 0.8),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.8)
        ..strokeWidth = w * 0.06
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      glass,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(2, w * 0.05)
        ..strokeJoin = StrokeJoin.round
        ..color = Duo.blueDark,
    );
  }

  @override
  bool shouldRepaint(_GlassPainter old) => old.fill != fill || old.t != t;
}

/// Pluie de gouttes et d'étoiles (écran de victoire), une seule fois.
class ConfettiRain extends StatelessWidget {
  const ConfettiRain({super.key});

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 2800),
          builder: (context, t, _) => CustomPaint(
            size: Size.infinite,
            painter: _ConfettiPainter(t),
          ),
        ),
      );
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.t);

  final double t;

  static final _pieces = List.generate(42, (i) {
    final r = math.Random(i * 7919);
    return (
      x: r.nextDouble(),
      delay: r.nextDouble() * 0.35,
      speed: 0.7 + r.nextDouble() * 0.6,
      spin: (r.nextDouble() - 0.5) * 8,
      sway: r.nextDouble() * 2 * math.pi,
      kind: i % 3,
      color: const [Duo.blue, Duo.gold, Duo.green, Duo.orange][i % 4],
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _pieces) {
      final local = ((t - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (local <= 0 || local >= 1) continue;
      final y = -20 + local * p.speed * (size.height + 40);
      final x = p.x * size.width + math.sin(p.sway + local * 6) * 18;
      final paint = Paint()..color = p.color.withValues(alpha: 1 - local * 0.6);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.spin * local);
      switch (p.kind) {
        case 0: // goutte
          canvas.drawPath(
            Path()
              ..moveTo(0, -8)
              ..quadraticBezierTo(6, 0, 0, 6)
              ..quadraticBezierTo(-6, 0, 0, -8),
            paint,
          );
        case 1: // étoile
          final star = Path();
          for (var k = 0; k < 10; k++) {
            final radius = k.isEven ? 7.0 : 3.0;
            final a = -math.pi / 2 + k * math.pi / 5;
            final point = Offset(math.cos(a) * radius, math.sin(a) * radius);
            k == 0
                ? star.moveTo(point.dx, point.dy)
                : star.lineTo(point.dx, point.dy);
          }
          canvas.drawPath(star..close(), paint);
        default: // confetti
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              const Rect.fromLTWH(-5, -3, 10, 6),
              const Radius.circular(2),
            ),
            paint,
          );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
