/// ScatterPainter — custom painter for battery % vs range plot.
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

import 'package:konapod/models/battery_observation.dart';

class ScatterPainter extends CustomPainter {
  final List<BatteryObservation> observations;
  final BatteryObservation? hovered;
  final Color textColor;
  final Color pointColor;
  final Color gridColor;

  ScatterPainter({
    required this.observations,
    required this.hovered,
    required this.textColor,
    required this.pointColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 52.0;
    const bottomPad = 40.0;
    const topPad = 24.0;
    const rightPad = 16.0;

    final plotW = size.width - leftPad - rightPad;
    final plotH = size.height - topPad - bottomPad;

    // Data ranges
    final minPct = 0.0;
    final maxPct = 100.0;
    final maxRange = observations.map((o) => o.rangeKm).reduce(max) * 1.05;
    final minRange = 0.0;

    // Helpers
    double toX(double pct) =>
        leftPad + (pct - minPct) / (maxPct - minPct) * plotW;
    double toY(double km) =>
        topPad + plotH - (km - minRange) / (maxRange - minRange) * plotH;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;
    final axisPaint = Paint()
      ..color = textColor.withValues(alpha: 0.8)
      ..strokeWidth = 1;
    final pointPaint = Paint()..color = pointColor;
    final textStyle = TextStyle(color: textColor, fontSize: 10);

    // Grid + X axis labels (battery %)
    for (int x = 0; x <= 10; x++) {
      final pct = x * 10.0;
      final px = toX(pct);
      canvas.drawLine(
        Offset(px, topPad),
        Offset(px, topPad + plotH),
        gridPaint,
      );
      _drawText(
        canvas,
        '${pct.toInt()}%',
        Offset(px - 8, topPad + plotH + 6),
        textStyle,
      );
    }

    // Y axis labels (range km)
    final rangeStep = _niceStep(maxRange, 6);
    for (double km = 0; km <= maxRange; km += rangeStep) {
      final py = toY(km);
      if (py < topPad) break;
      canvas.drawLine(
        Offset(leftPad, py),
        Offset(leftPad + plotW, py),
        gridPaint,
      );
      _drawText(canvas, '${km.toInt()} km', Offset(2, py - 6), textStyle);
    }

    // Axes
    canvas.drawLine(
      const Offset(leftPad, topPad),
      Offset(leftPad, topPad + plotH),
      axisPaint,
    );
    canvas.drawLine(
      Offset(leftPad, topPad + plotH),
      Offset(leftPad + plotW, topPad + plotH),
      axisPaint,
    );

    // Trend line (linear regression)
    if (observations.length >= 3) {
      final xs = observations.map((o) => o.batteryPct).toList();
      final ys = observations.map((o) => o.rangeKm).toList();
      final n = xs.length;
      final sumX = xs.reduce((a, b) => a + b);
      final sumY = ys.reduce((a, b) => a + b);
      final sumXY =
          List.generate(n, (i) => xs[i] * ys[i]).reduce((a, b) => a + b);
      final sumX2 = xs.map((x) => x * x).reduce((a, b) => a + b);
      final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
      final intercept = (sumY - slope * sumX) / n;
      final linePaint = Paint()
        ..color = pointColor.withValues(alpha: 0.35)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(toX(minPct), toY(slope * minPct + intercept)),
        Offset(toX(maxPct), toY(slope * maxPct + intercept)),
        linePaint,
      );
      // Annotation: km per 1%
      final kmPer1Pct = slope;
      _drawText(
        canvas,
        'slope: ${kmPer1Pct.toStringAsFixed(1)} km / 1%  '
        '≈ ${(kmPer1Pct * 100).toStringAsFixed(0)} km @ 100%',
        const Offset(leftPad + 8, topPad + 4),
        TextStyle(color: pointColor.withValues(alpha: 0.7), fontSize: 10),
      );
    }

    // Data points
    for (final o in observations) {
      final px = toX(o.batteryPct);
      final py = toY(o.rangeKm);
      if (px.isFinite && py.isFinite) {
        final isHovered = o == hovered;
        if (isHovered) {
          canvas.drawCircle(
            Offset(px, py),
            8,
            Paint()
              ..color = pointColor.withValues(alpha: 0.25)
              ..style = PaintingStyle.fill,
          );
          canvas.drawCircle(
            Offset(px, py),
            8,
            Paint()
              ..color = pointColor
              ..strokeWidth = 1.5
              ..style = PaintingStyle.stroke,
          );
        }
        canvas.drawCircle(Offset(px, py), isHovered ? 5 : 4, pointPaint);
      }
    }

    // Axis labels
    _drawText(
      canvas,
      'Battery %',
      Offset(leftPad + plotW / 2 - 24, size.height - 6),
      TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w500),
    );
    // Y label rotated — skip for simplicity, use header text instead
  }

  double _niceStep(double max, int targetTicks) {
    final rawStep = max / targetTicks;
    final magnitude = pow(10, (log(rawStep) / ln10).floor()).toDouble();
    final normalised = rawStep / magnitude;
    if (normalised <= 1) return magnitude;
    if (normalised <= 2) return 2 * magnitude;
    if (normalised <= 5) return 5 * magnitude;
    return 10 * magnitude;
  }

  void _drawText(Canvas canvas, String text, Offset offset, TextStyle style) {
    final span = TextSpan(text: text, style: style);
    final tp = TextPainter(text: span, textDirection: ui.TextDirection.ltr)
      ..layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(ScatterPainter old) =>
      old.observations != observations || old.hovered != hovered;
}

// ── Data table ────────────────────────────────────────────────────────────────
