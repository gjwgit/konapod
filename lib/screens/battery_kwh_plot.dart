/// Battery kWh scatter plots (% vs kWh, Range vs kWh).
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

enum KwhPlotMode { pctVsKwh, rangeVsKwh }

class BatteryKwhScatterPlot extends StatefulWidget {
  final List<BatteryObservation> observations;
  final KwhPlotMode mode;

  const BatteryKwhScatterPlot({
    super.key,
    required this.observations,
    required this.mode,
  });

  @override
  State<BatteryKwhScatterPlot> createState() => _BatteryKwhScatterPlotState();
}

class _BatteryKwhScatterPlotState extends State<BatteryKwhScatterPlot> {
  BatteryObservation? _hovered;
  Offset _hoverPos = Offset.zero;

  List<BatteryObservation> get _valid =>
      widget.observations.where((o) => o.remainKwh != null).toList();

  void _onHover(Offset pos, Size size) {
    const lp = 52.0, tp = 24.0, bp = 40.0, rp = 16.0;
    final pw = size.width - lp - rp;
    final ph = size.height - tp - bp;
    final obs = _valid;
    if (obs.isEmpty) return;

    final maxKwh = obs.map((o) => o.remainKwh!).reduce(max) * 1.05;
    final maxY = widget.mode == KwhPlotMode.pctVsKwh
        ? 100.0
        : obs.map((o) => o.rangeKm).reduce(max) * 1.05;

    double toX(double kwh) => lp + kwh / maxKwh * pw;
    double toY(double v) => tp + ph - v / maxY * ph;

    BatteryObservation? nearest;
    double minDist = double.infinity;
    for (final o in obs) {
      final x = toX(o.remainKwh!);
      final y =
          toY(widget.mode == KwhPlotMode.pctVsKwh ? o.batteryPct : o.rangeKm);
      final d = (pos.dx - x) * (pos.dx - x) + (pos.dy - y) * (pos.dy - y);
      if (d < minDist) {
        minDist = d;
        nearest = o;
      }
    }
    setState(() {
      _hovered = minDist < 400 ? nearest : null;
      _hoverPos = pos;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fmt = DateFormat('d MMM yyyy  HH:mm');
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return MouseRegion(
          onHover: (e) => _onHover(e.localPosition, size),
          onExit: (_) => setState(() => _hovered = null),
          child: GestureDetector(
            onTapDown: (e) => _onHover(e.localPosition, size),
            child: Stack(
              children: [
                CustomPaint(
                  size: size,
                  painter: _KwhPainter(
                    observations: _valid,
                    hovered: _hovered,
                    mode: widget.mode,
                    textColor: cs.onSurface,
                    pointColor: cs.secondary,
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

class _KwhPainter extends CustomPainter {
  final List<BatteryObservation> observations;
  final BatteryObservation? hovered;
  final KwhPlotMode mode;
  final Color textColor, pointColor, gridColor;

  _KwhPainter({
    required this.observations,
    required this.hovered,
    required this.mode,
    required this.textColor,
    required this.pointColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (observations.isEmpty) return;
    const lp = 52.0, tp = 24.0, bp = 40.0, rp = 16.0;
    final pw = size.width - lp - rp;
    final ph = size.height - tp - bp;

    final maxKwh = observations.map((o) => o.remainKwh!).reduce(max) * 1.05;
    final isPct = mode == KwhPlotMode.pctVsKwh;
    final maxY =
        isPct ? 100.0 : observations.map((o) => o.rangeKm).reduce(max) * 1.05;

    double toX(double kwh) => lp + kwh / maxKwh * pw;
    double toY(double v) => tp + ph - v / maxY * ph;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;
    final axisPaint = Paint()
      ..color = textColor.withValues(alpha: 0.8)
      ..strokeWidth = 1;
    final pointPaint = Paint()..color = pointColor;
    final ts = TextStyle(color: textColor, fontSize: 10);

    // X grid (kWh)
    final xStep = _niceStep(maxKwh, 6);
    for (double kwh = 0; kwh <= maxKwh; kwh += xStep) {
      final px = toX(kwh);
      canvas.drawLine(Offset(px, tp), Offset(px, tp + ph), gridPaint);
      _drawText(
        canvas,
        kwh.toStringAsFixed(0),
        Offset(px - 8, tp + ph + 6),
        ts,
      );
    }
    // Y grid
    final yStep = isPct ? 10.0 : _niceStep(maxY, 6);
    for (double v = 0; v <= maxY; v += yStep) {
      final py = toY(v);
      if (py < tp) break;
      canvas.drawLine(Offset(lp, py), Offset(lp + pw, py), gridPaint);
      _drawText(
        canvas,
        isPct ? '${v.toInt()}%' : '${v.toInt()} km',
        Offset(2, py - 6),
        ts,
      );
    }
    // Axes
    canvas.drawLine(const Offset(lp, tp), Offset(lp, tp + ph), axisPaint);
    canvas.drawLine(Offset(lp, tp + ph), Offset(lp + pw, tp + ph), axisPaint);

    // X axis label
    _drawText(
      canvas,
      'Battery remaining (kWh)',
      Offset(lp + pw / 2 - 50, size.height - 6),
      TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w500),
    );

    // Trend line
    if (observations.length >= 3) {
      final xs = observations.map((o) => o.remainKwh!).toList();
      final ys =
          observations.map((o) => isPct ? o.batteryPct : o.rangeKm).toList();
      final n = xs.length;
      final sx = xs.reduce((a, b) => a + b);
      final sy = ys.reduce((a, b) => a + b);
      final sxy =
          List.generate(n, (i) => xs[i] * ys[i]).reduce((a, b) => a + b);
      final sx2 = xs.map((x) => x * x).reduce((a, b) => a + b);
      final slope = (n * sxy - sx * sy) / (n * sx2 - sx * sx);
      final intercept = (sy - slope * sx) / n;
      final linePaint = Paint()
        ..color = pointColor.withValues(alpha: 0.35)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(toX(0), toY(intercept).clamp(tp, tp + ph)),
        Offset(toX(maxKwh), toY(slope * maxKwh + intercept).clamp(tp, tp + ph)),
        linePaint,
      );
    }

    // Points
    for (final o in observations) {
      final px = toX(o.remainKwh!);
      final py = toY(isPct ? o.batteryPct : o.rangeKm);
      if (!px.isFinite || !py.isFinite) continue;
      final isH = o == hovered;
      if (isH) {
        canvas.drawCircle(
          Offset(px, py),
          8,
          Paint()..color = pointColor.withValues(alpha: 0.25),
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
      canvas.drawCircle(Offset(px, py), isH ? 5 : 4, pointPaint);
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
  bool shouldRepaint(_KwhPainter old) =>
      old.observations != observations || old.hovered != hovered;
}

// ── Odo vs kWh/100km bar chart ────────────────────────────────────────────────

/// Bar chart: x = odometer km, y = kWh/100km for each observation.
/// Only observations with both odometerKm and remainKwh are plotted.
