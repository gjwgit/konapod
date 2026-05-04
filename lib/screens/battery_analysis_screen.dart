/// BatteryAnalysisScreen — plot and table of battery % vs range km.
///
// Time-stamp: <Sunday 2026-05-03 08:33:40 +1000 Graham Williams>
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

class BatteryScatterPlot extends StatefulWidget {
  final List<BatteryObservation> observations;

  const BatteryScatterPlot({super.key, required this.observations});

  @override
  State<BatteryScatterPlot> createState() => BatteryScatterPlotState();
}

class BatteryScatterPlotState extends State<BatteryScatterPlot> {
  BatteryObservation? _hovered;
  Offset _hoverPos = Offset.zero;

  // Hit-test: find nearest observation to the mouse position.
  void _onHover(Offset localPos, Size plotSize) {
    const leftPad = 52.0;
    const topPad = 24.0;
    const bottomPad = 40.0;
    const rightPad = 16.0;
    final plotW = plotSize.width - leftPad - rightPad;
    final plotH = plotSize.height - topPad - bottomPad;
    final obs = widget.observations;
    if (obs.isEmpty) return;

    final maxRange =
        obs.map((o) => o.rangeKm).reduce((a, b) => a > b ? a : b) * 1.05;

    double toX(double pct) => leftPad + pct / 100.0 * plotW;
    double toY(double km) => topPad + plotH - km / maxRange * plotH;

    BatteryObservation? nearest;
    double minDist = double.infinity;
    for (final o in obs) {
      final px = toX(o.batteryPct);
      final py = toY(o.rangeKm);
      final dx = localPos.dx - px;
      final dy = localPos.dy - py;
      final d = dx * dx + dy * dy;
      if (d < minDist) {
        minDist = d;
        nearest = o;
      }
    }
    setState(() {
      _hovered = (minDist < 400) ? nearest : null; // within ~20px
      _hoverPos = localPos;
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
                  painter: _ScatterPainter(
                    observations: widget.observations,
                    hovered: _hovered,
                    textColor: cs.onSurface,
                    pointColor: cs.primary,
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

class BatteryHoverTooltip extends StatelessWidget {
  final BatteryObservation obs;
  final Offset pos;
  final DateFormat fmt;
  final ColorScheme cs;
  final Size plotSize;

  const BatteryHoverTooltip({
    super.key,
    required this.obs,
    required this.pos,
    required this.fmt,
    required this.cs,
    required this.plotSize,
  });

  @override
  Widget build(BuildContext context) {
    const tipW = 200.0;
    const tipH = 80.0;
    const margin = 12.0;
    // Position tooltip so it stays inside the plot.
    double left = pos.dx + margin;
    double top = pos.dy - tipH / 2;
    if (left + tipW > plotSize.width) left = pos.dx - tipW - margin;
    top = top.clamp(0.0, plotSize.height - tipH);

    return Positioned(
      left: left,
      top: top,
      child: IgnorePointer(
        child: Container(
          width: tipW,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: cs.surface,
            border: Border.all(color: cs.primary.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withValues(alpha: 0.15),
                blurRadius: 6,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${fmt.format(obs.timestamp)}'
                '${obs.odometerKm != null ? '   ${obs.odometerKm!.toStringAsFixed(0)} km' : ''}',
                style: TextStyle(
                  fontSize: 11,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${obs.batteryPct.toStringAsFixed(1)}%  →  '
                '${obs.rangeKm.toStringAsFixed(0)} km',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: cs.primary,
                ),
              ),
              if (obs.remainKwh != null) ...[
                Text(
                  'Battery: ${obs.remainKwh!.toStringAsFixed(1)} kWh',
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
                Text(
                  '${(obs.rangeKm / obs.remainKwh!).toStringAsFixed(1)} km/kWh  '
                  '· ${(obs.remainKwh! / obs.rangeKm * 100).toStringAsFixed(1)} kWh/100km',
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ScatterPainter extends CustomPainter {
  final List<BatteryObservation> observations;
  final BatteryObservation? hovered;
  final Color textColor;
  final Color pointColor;
  final Color gridColor;

  _ScatterPainter({
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
  bool shouldRepaint(_ScatterPainter old) =>
      old.observations != observations || old.hovered != hovered;
}

// ── Data table ────────────────────────────────────────────────────────────────

class ObservationTable extends StatelessWidget {
  final List<BatteryObservation> observations;
  final void Function(BatteryObservation)? onDelete;

  const ObservationTable({
    super.key,
    required this.observations,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fmt = DateFormat('d MMM yyyy  HH:mm');
    // Show newest first.
    final rows = observations.reversed.toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                '${observations.length} observation'
                '${observations.length == 1 ? '' : 's'}',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 16,
            headingRowHeight: 32,
            dataRowMinHeight: 28,
            dataRowMaxHeight: 36,
            columns: const [
              DataColumn(label: Text('Date')),
              DataColumn(label: Text('%'), numeric: true),
              DataColumn(label: Text('Range km'), numeric: true),
              DataColumn(label: Text('kWh'), numeric: true),
              DataColumn(label: Text('km/kWh'), numeric: true),
              DataColumn(label: Text('kWh/100km'), numeric: true),
              DataColumn(label: Text('Odo km'), numeric: true),
              DataColumn(label: Text('')),
            ],
            rows: rows.map((o) {
              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      fmt.format(o.timestamp),
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  DataCell(
                    Text(
                      o.batteryPct.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  DataCell(
                    Text(
                      o.rangeKm.toStringAsFixed(0),
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  DataCell(
                    Text(
                      o.remainKwh != null
                          ? o.remainKwh!.toStringAsFixed(1)
                          : '—',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  DataCell(
                    Text(
                      o.remainKwh != null && o.remainKwh! > 0
                          ? (o.rangeKm / o.remainKwh!).toStringAsFixed(1)
                          : '—',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  DataCell(
                    Text(
                      o.remainKwh != null && o.rangeKm > 0
                          ? (o.remainKwh! / o.rangeKm * 100).toStringAsFixed(1)
                          : '—',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  DataCell(
                    Text(
                      o.odometerKm != null
                          ? o.odometerKm!.toStringAsFixed(0)
                          : '—',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  DataCell(
                    onDelete != null
                        ? IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 16,
                              color: Colors.red,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Delete this observation',
                            onPressed: () => onDelete!(o),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ── kWh scatter plots (% vs kWh, Range vs kWh) ───────────────────────────────

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
