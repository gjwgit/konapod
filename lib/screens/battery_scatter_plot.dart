/// Battery % vs range scatter plot and observation table.
///
// Time-stamp: <2026-05-04>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3

library;

import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import 'package:konapod/models/battery_observation.dart';
import 'package:konapod/screens/battery_scatter_painter.dart';

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
                  painter: ScatterPainter(
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
