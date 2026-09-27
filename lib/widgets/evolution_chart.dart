import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../hydration_controller.dart';
import '../models/plan.dart';
import '../theme/duo.dart';
import 'duo_widgets.dart';

const _months = [
  'janv.',
  'févr.',
  'mars',
  'avr.',
  'mai',
  'juin',
  'juil.',
  'août',
  'sept.',
  'oct.',
  'nov.',
  'déc.',
];

String _liters(double l) => formatLiters((l * 1000).round());

/// « Mon évolution » : courbe du mois (litres par jour) ou de l'année
/// (moyenne par jour, mois par mois), avec l'objectif en pointillés.
class EvolutionSection extends StatefulWidget {
  const EvolutionSection({super.key, required this.controller});

  final HydrationController controller;

  @override
  State<EvolutionSection> createState() => _EvolutionSectionState();
}

class _EvolutionSectionState extends State<EvolutionSection> {
  bool _year = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final points = _year ? c.lastMonths(12) : c.lastDays(30);
    // Aujourd'hui n'est pas fini : il ne compte pas dans les chiffres.
    final values = (_year ? points : points.take(points.length - 1))
        .map((p) => p.liters)
        .whereType<double>()
        .toList();
    final goal = c.goalMl / 1000;
    final average =
        values.isEmpty ? 0.0 : values.reduce((a, b) => a + b) / values.length;
    final best = values.isEmpty ? 0.0 : values.reduce(math.max);
    final goalDays = values.where((v) => goal > 0 && v >= goal).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: Text('MON ÉVOLUTION', style: Duo.label)),
            _Toggle(
              year: _year,
              onChanged: (year) => setState(() => _year = year),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DuoCard(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _year
                    ? 'Moyenne par jour, sur 12 mois'
                    : 'Litres bus par jour, sur 30 jours',
                style: Duo.heading.copyWith(fontSize: 15),
              ),
              const SizedBox(height: 8),
              EvolutionChart(
                key: ValueKey(_year),
                points: points,
                goal: goal,
                yearly: _year,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _Figure(label: 'Moyenne / jour', value: _liters(average)),
                  _Figure(
                    label: _year ? 'Meilleur mois' : 'Meilleur jour',
                    value: _liters(best),
                  ),
                  _Figure(
                    label: _year ? 'Mois à l\'objectif' : 'Jours à l\'objectif',
                    value: '$goalDays',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.year, required this.onChanged});

  final bool year;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget option(String label, bool value) {
      final selected = value == year;
      return Semantics(
        button: true,
        selected: selected,
        child: GestureDetector(
          onTap: () => onChanged(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: selected ? Duo.blueLight : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? Duo.blue : Duo.border,
                width: 2,
              ),
            ),
            child: Text(
              label,
              style: Duo.label.copyWith(
                color: selected ? Duo.blueDark : Duo.gray,
                fontSize: 12,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        option('MOIS', false),
        const SizedBox(width: 6),
        option('ANNÉE', true),
      ],
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: Duo.heading.copyWith(fontSize: 17)),
          Text(label, style: Duo.body.copyWith(fontSize: 12)),
        ],
      ),
    );
  }
}

/// Courbe tactile : toucher ou glisser pour lire une valeur.
class EvolutionChart extends StatefulWidget {
  const EvolutionChart({
    super.key,
    required this.points,
    required this.goal,
    required this.yearly,
  });

  final List<ChartPoint> points;
  final double goal;
  final bool yearly;

  @override
  State<EvolutionChart> createState() => _EvolutionChartState();
}

class _EvolutionChartState extends State<EvolutionChart> {
  /// Par défaut, la dernière valeur (aujourd'hui ou ce mois-ci) est lue.
  late int _selected = widget.points.length - 1;

  void _select(Offset local, double width) {
    final n = widget.points.length;
    final plot = width - _ChartPainter.left - _ChartPainter.right;
    final i = ((local.dx - _ChartPainter.left) / plot * (n - 1)).round();
    setState(() => _selected = i.clamp(0, n - 1));
  }

  String _dateLabel(DateTime d) => widget.yearly
      ? '${_months[d.month - 1]} ${d.year}'
      : '${d.day} ${_months[d.month - 1]}';

  bool get _todayInProgress => !widget.yearly;

  @override
  Widget build(BuildContext context) {
    final p = widget.points[_selected];
    final summary = widget.points
        .where((p) => p.liters != null)
        .map((p) => '${_dateLabel(p.date)} : ${_liters(p.liters!)}')
        .join(', ');
    return Semantics(
      label: 'Courbe. $summary',
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, constraints) => GestureDetector(
          onTapDown: (d) => _select(d.localPosition, constraints.maxWidth),
          onHorizontalDragUpdate: (d) =>
              _select(d.localPosition, constraints.maxWidth),
          child: CustomPaint(
            size: Size(constraints.maxWidth, 200),
            painter: _ChartPainter(
              points: widget.points,
              goal: widget.goal,
              selected: _selected,
              lastInProgress: _todayInProgress,
              tooltip: _todayInProgress && _selected == widget.points.length - 1
                  ? 'Aujourd\'hui · ${_liters(p.liters ?? 0)} (en cours)'
                  : '${_dateLabel(p.date)} · '
                      '${p.liters == null ? '—' : _liters(p.liters!)}',
              xLabel: (i) {
                final d = widget.points[i].date;
                final n = widget.points.length;
                if (widget.yearly) {
                  return (n - 1 - i).isEven ? _months[d.month - 1] : null;
                }
                return (n - 1 - i) % 7 == 0 ? '${d.day}/${d.month}' : null;
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.points,
    required this.goal,
    required this.selected,
    required this.tooltip,
    required this.xLabel,
    required this.lastInProgress,
  });

  static const left = 34.0;
  static const right = 8.0;
  static const top = 34.0;
  static const bottom = 22.0;

  final List<ChartPoint> points;
  final double goal;
  final int selected;
  final String tooltip;
  final String? Function(int) xLabel;

  /// Le dernier point (aujourd'hui) est en cours : tracé en pointillés.
  final bool lastInProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final plot = Rect.fromLTRB(
      left,
      top,
      size.width - right,
      size.height - bottom,
    );
    final values = points.map((p) => p.liters).whereType<double>().toList();
    final peak = [goal, ...values].fold(0.0, math.max);
    final step = peak <= 2 ? 0.5 : (peak <= 5 ? 1.0 : 2.0);
    final yMax = math.max(step, (peak / step).ceil() * step);

    double x(int i) =>
        plot.left +
        (points.length == 1 ? 0 : i / (points.length - 1)) * plot.width;
    double y(double v) => plot.bottom - v / yMax * plot.height;

    // Grille discrète et graduations.
    final grid = Paint()
      ..color = Duo.border
      ..strokeWidth = 1;
    for (var v = 0.0; v <= yMax + 1e-9; v += step) {
      canvas.drawLine(Offset(plot.left, y(v)), Offset(plot.right, y(v)), grid);
      _text(
        canvas,
        v == 0 ? '0' : _liters(v),
        Offset(0, y(v) - 7),
        width: left - 6,
        align: TextAlign.right,
      );
    }
    for (var i = 0; i < points.length; i++) {
      final label = xLabel(i);
      if (label != null) {
        _text(
          canvas,
          label,
          Offset(x(i) - 24, plot.bottom + 5),
          width: 48,
          align: TextAlign.center,
        );
      }
    }

    // Objectif en pointillés.
    if (goal > 0) {
      final dash = Paint()
        ..color = Duo.gray
        ..strokeWidth = 1.5;
      for (var dx = plot.left; dx < plot.right; dx += 8) {
        canvas.drawLine(
          Offset(dx, y(goal)),
          Offset(math.min(dx + 4, plot.right), y(goal)),
          dash,
        );
      }
      final label = _layout('Objectif ${_liters(goal)}', color: Duo.textLight);
      final at = Offset(plot.left + 4, y(goal) - label.height - 2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          (at & label.size).inflate(2),
          const Radius.circular(4),
        ),
        Paint()..color = Colors.white.withValues(alpha: 0.9),
      );
      label.paint(canvas, at);
    }

    // Courbe, coupée là où il n'y a pas encore de données.
    final segments = <List<Offset>>[[]];
    final solidCount = lastInProgress ? points.length - 1 : points.length;
    for (var i = 0; i < solidCount; i++) {
      final v = points[i].liters;
      if (v == null) {
        if (segments.last.isNotEmpty) segments.add([]);
      } else {
        segments.last.add(Offset(x(i), y(v)));
      }
    }
    for (final seg in segments.where((s) => s.isNotEmpty)) {
      final line = Path()..moveTo(seg.first.dx, seg.first.dy);
      for (final p in seg.skip(1)) {
        line.lineTo(p.dx, p.dy);
      }
      final area = Path.from(line)
        ..lineTo(seg.last.dx, plot.bottom)
        ..lineTo(seg.first.dx, plot.bottom)
        ..close();
      canvas.drawPath(
        area,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Duo.blue.withValues(alpha: 0.22),
              Duo.blue.withValues(alpha: 0.02),
            ],
          ).createShader(plot),
      );
      canvas.drawPath(
        line,
        Paint()
          ..color = Duo.blueDark
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
      if (seg.length == 1) {
        canvas.drawCircle(seg.first, 3, Paint()..color = Duo.blueDark);
      }
    }
    final today = points.last.liters;
    if (lastInProgress && today != null && points.length > 1) {
      final to = Offset(x(points.length - 1), y(today));
      final prev = points[points.length - 2].liters;
      if (prev != null) {
        final from = Offset(x(points.length - 2), y(prev));
        final dash = Paint()
          ..color = Duo.blueDark
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round;
        const parts = 5;
        for (var k = 0; k < parts; k++) {
          canvas.drawLine(
            Offset.lerp(from, to, k / parts)!,
            Offset.lerp(from, to, (k + 0.5) / parts)!,
            dash,
          );
        }
      }
    }

    // Valeur lue : repère vertical, point et bulle.
    final sx = x(selected);
    canvas.drawLine(
      Offset(sx, plot.top),
      Offset(sx, plot.bottom),
      Paint()
        ..color = Duo.border
        ..strokeWidth = 2,
    );
    final v = points[selected].liters;
    if (v != null) {
      final c = Offset(sx, y(v));
      canvas.drawCircle(c, 6, Paint()..color = Colors.white);
      canvas.drawCircle(c, 4.5, Paint()..color = Duo.blueDark);
    }
    final tp = _layout(tooltip, bold: true);
    final w = tp.width + 20;
    final bx =
        (sx - w / 2).clamp(0.0, math.max(0.0, size.width - w)).toDouble();
    final box = RRect.fromLTRBR(bx, 0, bx + w, 26, const Radius.circular(10));
    canvas.drawRRect(box, Paint()..color = Colors.white);
    canvas.drawRRect(
      box,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Duo.border,
    );
    tp.paint(canvas, Offset(bx + 10, 13 - tp.height / 2));
  }

  TextPainter _layout(
    String text, {
    bool bold = false,
    Color color = Duo.text,
    double? width,
    TextAlign align = TextAlign.left,
  }) =>
      TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontFamily: Duo.font,
            fontSize: bold ? 13 : 11,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            color: bold ? Duo.text : color,
          ),
        ),
        textAlign: align,
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(minWidth: width ?? 0, maxWidth: width ?? double.infinity);

  void _text(
    Canvas canvas,
    String text,
    Offset at, {
    required double width,
    TextAlign align = TextAlign.left,
    Color color = Duo.gray,
  }) =>
      _layout(text, color: color, width: width, align: align).paint(canvas, at);

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.selected != selected || old.points != points || old.goal != goal;
}
