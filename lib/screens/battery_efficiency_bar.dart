/// Battery efficiency bar chart (odo vs kWh/100km).
///
// Time-stamp: <2026-05-04>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3

library;

import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import 'package:konapod/models/battery_observation.dart';
import 'package:konapod/screens/battery_scatter_plot.dart';

class BatteryEfficiencyBarChart extends StatefulWidget {
  final List<BatteryObservation> observations;

  const BatteryEfficiencyBarChart({super.key, required this.observations});

  @override
  State<BatteryEfficiencyBarChart> createState() =>
      _BatteryEfficiencyBarChartState();
}

class _BatteryEfficiencyBarChartState extends State<BatteryEfficiencyBarChart> {
  BatteryObservation? _hovered;
  Offset _hoverPos = Offset.zero;

  List<BatteryObservation> get _valid => widget.observations
      .where(
        (o) => o.odometerKm != null && o.remainKwh != null && o.rangeKm > 0,
      )
      .toList();

  void _onHover(
    Offset pos,
    Size size,
    List<BatteryObservation> obs,
    double minOdo,
    double maxOdo,
    double maxY,
    double lp,
    double tp,
    double bp,
    double rp,
  ) {
    final pw = size.width - lp - rp;
    if (obs.isEmpty || pw <= 0) return;

    final barW = (pw / obs.length * 0.6).clamp(4.0, 40.0);

    BatteryObservation? nearest;
    double minDist = double.infinity;
    for (int i = 0; i < obs.length; i++) {
      final cx = lp + (i + 0.5) * pw / obs.length;
      final d = (pos.dx - cx).abs();
      if (d < minDist) {
        minDist = d;
        nearest = obs[i];
      }
    }
    setState(() {
      _hovered = minDist < (barW + 8) ? nearest : null;
      _hoverPos = pos;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fmt = DateFormat('d MMM yyyy  HH:mm');
    final obs = _valid;

    if (obs.isEmpty) {
      return Center(
        child: Text(
          'No efficiency data yet — needs odometer and kWh readings.',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
      );
    }

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        const lp = 60.0, tp = 24.0, bp = 40.0, rp = 16.0;

        final maxY =
            obs.map((o) => o.remainKwh! / o.rangeKm * 100).reduce(max) * 1.15;
        final minOdo = obs.map((o) => o.odometerKm!).reduce(min);
        final maxOdo = obs.map((o) => o.odometerKm!).reduce(max);

        return MouseRegion(
          onHover: (e) => _onHover(
            e.localPosition,
            size,
            obs,
            minOdo,
            maxOdo,
            maxY,
            lp,
            tp,
            bp,
            rp,
          ),
          onExit: (_) => setState(() => _hovered = null),
          child: GestureDetector(
            onTapDown: (e) => _onHover(
              e.localPosition,
              size,
              obs,
              minOdo,
              maxOdo,
              maxY,
              lp,
              tp,
              bp,
              rp,
            ),
            child: Stack(
              children: [
                CustomPaint(
                  size: size,
                  painter: _EfficiencyBarPainter(
                    observations: obs,
                    hovered: _hovered,
                    maxY: maxY,
                    textColor: cs.onSurface,
                    barColor: cs.tertiary,
                    hoveredColor: cs.primary,
                    gridColor: cs.outlineVariant,
                  ),
                ),
                if (_hovered != null)
                  BatteryHoverTooltip(
                    obs: _hovered!,
                    pos: _hoverPos,
                    fmt: fmt,
                    cs: cs,
                    plotSize: size,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EfficiencyBarPainter extends CustomPainter {
  final List<BatteryObservation> observations;
  final BatteryObservation? hovered;
  final double maxY;
  final Color textColor, barColor, hoveredColor, gridColor;

  _EfficiencyBarPainter({
    required this.observations,
    required this.hovered,
    required this.maxY,
    required this.textColor,
    required this.barColor,
    required this.hoveredColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const lp = 60.0, tp = 24.0, bp = 40.0, rp = 16.0;
    final pw = size.width - lp - rp;
    final ph = size.height - tp - bp;
    final n = observations.length;
    if (n == 0 || pw <= 0) return;

    final slotW = pw / n;
    final barW = (slotW * 0.6).clamp(4.0, 40.0);

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;
    final axisPaint = Paint()
      ..color = textColor.withValues(alpha: 0.8)
      ..strokeWidth = 1;
    final ts = TextStyle(color: textColor, fontSize: 10);

    // Y grid and labels (kWh/100km)
    final yStep = _niceStep(maxY, 5);
    for (double v = 0; v <= maxY; v += yStep) {
      final py = tp + ph - v / maxY * ph;
      if (py < tp) break;
      canvas.drawLine(Offset(lp, py), Offset(lp + pw, py), gridPaint);
      _drawText(canvas, v.toStringAsFixed(1), Offset(2, py - 6), ts);
    }

    // Axes
    canvas.drawLine(const Offset(lp, tp), Offset(lp, tp + ph), axisPaint);
    canvas.drawLine(Offset(lp, tp + ph), Offset(lp + pw, tp + ph), axisPaint);

    // Y axis label
    _drawText(
      canvas,
      'kWh/100km',
      Offset(lp + pw / 2 - 30, size.height - 6),
      TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w500),
    );

    // Bars
    for (int i = 0; i < n; i++) {
      final o = observations[i];
      final efficiency = o.remainKwh! / o.rangeKm * 100;
      final cx = lp + (i + 0.5) * slotW;
      final barH = (efficiency / maxY * ph).clamp(0.0, ph);
      final isH = o == hovered;

      final rect = Rect.fromLTWH(
        cx - barW / 2,
        tp + ph - barH,
        barW,
        barH,
      );
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          rect,
          topLeft: const Radius.circular(3),
          topRight: const Radius.circular(3),
        ),
        Paint()..color = isH ? hoveredColor : barColor.withValues(alpha: 0.75),
      );

      // Odo label below bar
      if (o.odometerKm != null) {
        final label = '${(o.odometerKm! / 1000).toStringAsFixed(0)}k';
        _drawText(canvas, label, Offset(cx - 10, tp + ph + 6), ts);
      }
    }
  }

  double _niceStep(double max, int ticks) {
    final raw = max / ticks;
    final mag = pow(10, (log(raw) / ln10).floor()).toDouble();
    final n = raw / mag;
    if (n <= 1) return mag;
    if (n <= 2) return 2 * mag;
    if (n <= 5) return 5 * mag;
    return 10 * mag;
  }

  void _drawText(Canvas c, String t, Offset o, TextStyle s) {
    final tp2 = TextPainter(
      text: TextSpan(text: t, style: s),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    tp2.paint(c, o);
  }

  @override
  bool shouldRepaint(_EfficiencyBarPainter old) =>
      old.observations != observations || old.hovered != hovered;
}
