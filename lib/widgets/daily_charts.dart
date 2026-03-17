/// Daily distance, energy consumption and regen overlay bar charts.
///
// Time-stamp: <Tuesday 2026-03-17 12:05:41 +1100 Graham Williams>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://opensource.org/license/gpl-3-0
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later
// version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
// details.
//
// You should have received a copy of the GNU General Public License along with
// this program.  If not, see <https://opensource.org/license/gpl-3-0>.
///
/// Authors: Claude, Graham Williams

library;

import 'package:flutter/material.dart';

import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import 'package:konapod/models/vehicle.dart';
import 'package:konapod/theme/hyundai_theme.dart';

// ── Shared colours for energy breakdown ──────────────────────────────────────

const _colEngine = Color(0xFF002C5F); // Hyundai navy
const _colClimate = Color(0xFF00AAD2); // Hyundai accent cyan
const _colElectronics = Color(0xFFFFB400); // warning amber
const _colBatteryCare = Color(0xFF00C896); // success green

// ── Daily Distance chart ──────────────────────────────────────────────────────

class DailyDistanceChart extends StatefulWidget {
  final List<DailyDrivingStat> stats;
  const DailyDistanceChart({super.key, required this.stats});
  @override
  State<DailyDistanceChart> createState() => _DailyDistanceChartState();
}

class _DailyDistanceChartState extends State<DailyDistanceChart> {
  int? _touched;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final stats = widget.stats;
    final maxY = stats.map((d) => d.distanceKm).reduce((a, b) => a > b ? a : b);
    return _ChartCard(
      child: BarChart(
        BarChartData(
          maxY: (maxY * 1.25).ceilToDouble(),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (g, _, rod, __) {
                final d = stats[g.x];
                return BarTooltipItem(
                  '${DateFormat('EEE d MMM').format(d.date)}\n',
                  TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  children: [
                    TextSpan(
                      text: '${d.distanceKm.toStringAsFixed(1)} km',
                      style: const TextStyle(
                        color: HyundaiColors.accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                );
              },
            ),
            touchCallback: (_, r) =>
                setState(() => _touched = r?.spot?.touchedBarGroupIndex),
          ),
          titlesData: _bottomLeftWithTop(
            cs,
            stats.length,
            (i) => DateFormat('d/M').format(stats[i].date),
            (v) => '${v.toInt()}',
            (i) => '${stats[i].distanceKm.round()}',
            interval: (maxY / 4).ceilToDouble().clamp(1, double.infinity),
          ),
          gridData:
              _grid(cs, (maxY / 4).ceilToDouble().clamp(1, double.infinity)),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(
            stats.length,
            (i) => BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: stats[i].distanceKm,
                  color: _touched == i
                      ? HyundaiColors.primary
                      : HyundaiColors.accent,
                  width: _barWidth(stats.length),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Daily Energy Consumption chart (stacked bars + regen overlay) ────────────

const _colRegen = Color(0xFF6B8FBF); // pale tint of engine navy

class DailyEnergyChart extends StatefulWidget {
  final List<DailyDrivingStat> stats;
  const DailyEnergyChart({super.key, required this.stats});
  @override
  State<DailyEnergyChart> createState() => _DailyEnergyChartState();
}

class _DailyEnergyChartState extends State<DailyEnergyChart> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final stats = widget.stats;
    final maxY = stats
        .map((d) => (d.totalConsumed ?? 0).toDouble())
        .reduce((a, b) => a > b ? a : b);
    final chartMaxY = (maxY * 1.25).ceilToDouble();
    final interval = (maxY / 4).ceilToDouble().clamp(1.0, double.infinity);
    final barW = _barWidth(stats.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ChartCard(
          child: BarChart(
            BarChartData(
              maxY: chartMaxY,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (g, _, rod, rodIndex) {
                    final d = stats[g.x];
                    return BarTooltipItem(
                      '${DateFormat('EEE d MMM').format(d.date)}\n',
                      TextStyle(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                      children: _energySpans(d),
                    );
                  },
                ),
              ),
              titlesData: _bottomLeftWithTop(
                cs,
                stats.length,
                (i) => DateFormat('d/M').format(stats[i].date),
                (v) => (v / 1000).toStringAsFixed(1),
                (i) {
                  final d = stats[i];
                  final net = (d.totalConsumed ?? 0).toDouble() -
                      (d.regeneratedEnergy ?? 0).toDouble();
                  return net > 0 ? (net / 1000).toStringAsFixed(2) : null;
                },
                interval: interval,
              ),
              gridData: _grid(cs, interval),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(stats.length, (i) {
                final d = stats[i];
                final engine = (d.engineConsumption ?? 0).toDouble();
                final climate = (d.climateConsumption ?? 0).toDouble();
                final elec = (d.electronicsConsumption ?? 0).toDouble();
                final care = (d.batteryCareConsumption ?? 0).toDouble();
                final regen =
                    ((d.regeneratedEnergy ?? 0).toDouble()).clamp(0.0, engine);

                return BarChartGroupData(
                  x: i,
                  barsSpace: -barW, // overlap the two rods exactly
                  barRods: [
                    // Rod 1: stacked consumption
                    BarChartRodData(
                      toY: engine + climate + elec + care,
                      width: barW,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                      rodStackItems: [
                        BarChartRodStackItem(0, engine, _colEngine),
                        BarChartRodStackItem(
                          engine,
                          engine + climate,
                          _colClimate,
                        ),
                        BarChartRodStackItem(
                          engine + climate,
                          engine + climate + elec,
                          _colElectronics,
                        ),
                        BarChartRodStackItem(
                          engine + climate + elec,
                          engine + climate + elec + care,
                          _colBatteryCare,
                        ),
                      ],
                    ),
                    // Rod 2: regen hatch overlay — same width, drawn on top
                    if (regen > 0)
                      BarChartRodData(
                        toY: regen,
                        width: barW,
                        borderRadius: BorderRadius.zero,
                        color: Colors.transparent,
                        rodStackItems: [
                          BarChartRodStackItem(
                            0,
                            regen,
                            _colRegen.withValues(alpha: 0.45),
                          ),
                        ],
                        backDrawRodData: BackgroundBarChartRodData(
                          show: false,
                        ),
                      ),
                  ],
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _Legend(),
      ],
    );
  }
}

// ── Energy tooltip helper ─────────────────────────────────────────────────────

List<TextSpan> _energySpans(DailyDrivingStat d) {
  String kw(num? v) => '${((v ?? 0) / 1000).toStringAsFixed(2)} kWh';
  TextSpan s(String t, Color c) =>
      TextSpan(text: t, style: TextStyle(color: c, fontSize: 11));
  return [
    s('Total: ${kw(d.totalConsumed)}\n', Colors.white),
    s('Engine: ${kw(d.engineConsumption)}\n', _colEngine),
    s('Climate: ${kw(d.climateConsumption)}\n', _colClimate),
    s('Electronics: ${kw(d.electronicsConsumption)}\n', _colElectronics),
    s('Battery care: ${kw(d.batteryCareConsumption)}\n', _colBatteryCare),
    s('↺ Regen: ${kw(d.regeneratedEnergy)}', _colRegen),
  ];
}

// ── Shared helpers ────────────────────────────────────────────────────────────

double _barWidth(int count) => count <= 7
    ? 22.0
    : count <= 14
        ? 14.0
        : 8.0;

// FlTitlesData _bottomLeft(
//   ColorScheme cs,
//   int count,
//   String Function(int) bottomLabel,
//   String Function(double) leftLabel, {
//   required double interval,
// }) =>
//     FlTitlesData(
//       leftTitles: AxisTitles(
//         sideTitles: SideTitles(
//           showTitles: true,
//           reservedSize: 42,
//           interval: interval,
//           getTitlesWidget: (v, _) => Text(
//             leftLabel(v),
//             style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10),
//           ),
//         ),
//       ),
//       bottomTitles: AxisTitles(
//         sideTitles: SideTitles(
//           showTitles: true,
//           reservedSize: 28,
//           interval: count <= 7 ? 1 : (count / 5).ceilToDouble(),
//           getTitlesWidget: (v, _) {
//             final i = v.toInt();
//             if (i < 0 || i >= count) return const SizedBox();
//             return Padding(
//               padding: const EdgeInsets.only(top: 4),
//               child: Text(
//                 bottomLabel(i),
//                 style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10),
//               ),
//             );
//           },
//         ),
//       ),
//       rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//       topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//     );

FlGridData _grid(ColorScheme cs, double interval) => FlGridData(
      drawVerticalLine: false,
      horizontalInterval: interval,
      getDrawingHorizontalLine: (_) =>
          FlLine(color: cs.outlineVariant, strokeWidth: 0.5),
    );

/// Like _bottomLeft but adds net consumption (total − regen) labels on top.
FlTitlesData _bottomLeftWithTop(
  ColorScheme cs,
  int count,
  String Function(int) bottomLabel,
  String Function(double) leftLabel,
  String? Function(int) topLabel, {
  required double interval,
}) {
  return FlTitlesData(
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 42,
        interval: interval,
        getTitlesWidget: (v, _) => Text(
          leftLabel(v),
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10),
        ),
      ),
    ),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 28,
        interval: count <= 7 ? 1 : (count / 5).ceilToDouble(),
        getTitlesWidget: (v, _) {
          final i = v.toInt();
          if (i < 0 || i >= count) return const SizedBox();
          return Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              bottomLabel(i),
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10),
            ),
          );
        },
      ),
    ),
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    topTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 18,
        getTitlesWidget: (v, _) {
          final i = v.toInt();
          if (i < 0 || i >= count) return const SizedBox();
          final label = topLabel(i);
          if (label == null) return const SizedBox();
          return Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              label,
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        },
      ),
    ),
  );
}

class _ChartCard extends StatelessWidget {
  final Widget child;
  const _ChartCard({required this.child});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: [
        _Dot('Engine', _colEngine, cs),
        _Dot('Climate', _colClimate, cs),
        _Dot('Electronics', _colElectronics, cs),
        _Dot('Battery care', _colBatteryCare, cs),
        _Dot('Regen', _colRegen.withValues(alpha: 0.55), cs),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final String label;
  final Color color;
  final ColorScheme cs;
  const _Dot(this.label, this.color, this.cs);
  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
      );
}
