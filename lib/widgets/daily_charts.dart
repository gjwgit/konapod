import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/vehicle.dart';
import '../theme/hyundai_theme.dart';

// ── Shared colours for energy breakdown ──────────────────────────────────────

const _colEngine      = Color(0xFF002C5F); // Hyundai navy
const _colClimate     = Color(0xFF00AAD2); // Hyundai accent cyan
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
    final cs    = Theme.of(context).colorScheme;
    final stats = widget.stats;
    final maxY  = stats.map((d) => d.distanceKm).reduce((a, b) => a > b ? a : b);
    return _ChartCard(
      child: BarChart(BarChartData(
        maxY: (maxY * 1.25).ceilToDouble(),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (g, _, rod, __) {
              final d = stats[g.x];
              return BarTooltipItem(
                '${DateFormat('EEE d MMM').format(d.date)}\n',
                TextStyle(color: cs.onSurface,
                    fontWeight: FontWeight.w600, fontSize: 12),
                children: [TextSpan(
                  text: '${d.distanceKm.toStringAsFixed(1)} km',
                  style: const TextStyle(color: HyundaiColors.accent,
                      fontWeight: FontWeight.w700, fontSize: 13),
                )],
              );
            },
          ),
          touchCallback: (_, r) =>
              setState(() => _touched = r?.spot?.touchedBarGroupIndex),
        ),
        titlesData: _bottomLeft(cs, stats.length,
            (i) => DateFormat('d/M').format(stats[i].date),
            (v) => '${v.toInt()}',
            interval: (maxY / 4).ceilToDouble().clamp(1, double.infinity)),
        gridData: _grid(cs, (maxY / 4).ceilToDouble().clamp(1, double.infinity)),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(stats.length, (i) => BarChartGroupData(
          x: i,
          barRods: [BarChartRodData(
            toY: stats[i].distanceKm,
            color: _touched == i ? HyundaiColors.primary : HyundaiColors.accent,
            width: _barWidth(stats.length),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          )],
        )),
      )),
    );
  }
}

// ── Daily Energy Consumption chart (stacked bars) ────────────────────────────

class DailyEnergyChart extends StatefulWidget {
  final List<DailyDrivingStat> stats;
  const DailyEnergyChart({super.key, required this.stats});
  @override
  State<DailyEnergyChart> createState() => _DailyEnergyChartState();
}

class _DailyEnergyChartState extends State<DailyEnergyChart> {
  int? _touched;
  @override
  Widget build(BuildContext context) {
    final cs    = Theme.of(context).colorScheme;
    final stats = widget.stats;
    final maxY  = stats
        .map((d) => (d.totalConsumed ?? 0).toDouble())
        .reduce((a, b) => a > b ? a : b);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _ChartCard(
        child: BarChart(BarChartData(
          maxY: (maxY * 1.25).ceilToDouble(),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (g, _, rod, __) {
                final d = stats[g.x];
                final total = d.totalConsumed ?? 0;
                return BarTooltipItem(
                  '${DateFormat('EEE d MMM').format(d.date)}\n',
                  TextStyle(color: cs.onSurface,
                      fontWeight: FontWeight.w600, fontSize: 11),
                  children: _energySpans(d),
                );
              },
            ),
            touchCallback: (_, r) =>
                setState(() => _touched = r?.spot?.touchedBarGroupIndex),
          ),
          titlesData: _bottomLeft(cs, stats.length,
              (i) => DateFormat('d/M').format(stats[i].date),
              (v) => '${(v / 1000).toStringAsFixed(1)}',
              interval: (maxY / 4).ceilToDouble().clamp(1, double.infinity)),
          gridData: _grid(cs, (maxY / 4).ceilToDouble().clamp(1, double.infinity)),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(stats.length, (i) {
            final d = stats[i];
            final engine   = (d.engineConsumption ?? 0).toDouble();
            final climate  = (d.climateConsumption ?? 0).toDouble();
            final elec     = (d.electronicsConsumption ?? 0).toDouble();
            final care     = (d.batteryCareConsumption ?? 0).toDouble();
            final w = _barWidth(stats.length);
            return BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: engine + climate + elec + care,
                width: w,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4)),
                rodStackItems: [
                  BarChartRodStackItem(0, engine, _colEngine),
                  BarChartRodStackItem(engine, engine + climate, _colClimate),
                  BarChartRodStackItem(engine + climate,
                      engine + climate + elec, _colElectronics),
                  BarChartRodStackItem(engine + climate + elec,
                      engine + climate + elec + care, _colBatteryCare),
                ],
              ),
            ]);
          }),
        )),
      ),
      const SizedBox(height: 10),
      _Legend(),
    ]);
  }
}

// ── Daily Regenerated Energy chart ───────────────────────────────────────────

class DailyRegenChart extends StatefulWidget {
  final List<DailyDrivingStat> stats;
  const DailyRegenChart({super.key, required this.stats});
  @override
  State<DailyRegenChart> createState() => _DailyRegenChartState();
}

class _DailyRegenChartState extends State<DailyRegenChart> {
  int? _touched;
  @override
  Widget build(BuildContext context) {
    final cs    = Theme.of(context).colorScheme;
    final stats = widget.stats;
    final maxY  = stats
        .map((d) => (d.regeneratedEnergy ?? 0).toDouble())
        .reduce((a, b) => a > b ? a : b);

    return _ChartCard(
      child: BarChart(BarChartData(
        maxY: (maxY * 1.25).ceilToDouble(),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (g, _, rod, __) {
              final d = stats[g.x];
              return BarTooltipItem(
                '${DateFormat('EEE d MMM').format(d.date)}\n',
                TextStyle(color: cs.onSurface,
                    fontWeight: FontWeight.w600, fontSize: 12),
                children: [TextSpan(
                  text: '${((d.regeneratedEnergy ?? 0) / 1000).toStringAsFixed(2)} kWh',
                  style: const TextStyle(color: HyundaiColors.success,
                      fontWeight: FontWeight.w700, fontSize: 13),
                )],
              );
            },
          ),
          touchCallback: (_, r) =>
              setState(() => _touched = r?.spot?.touchedBarGroupIndex),
        ),
        titlesData: _bottomLeft(cs, stats.length,
            (i) => DateFormat('d/M').format(stats[i].date),
            (v) => '${(v / 1000).toStringAsFixed(1)}',
            interval: (maxY / 4).ceilToDouble().clamp(1, double.infinity)),
        gridData: _grid(cs, (maxY / 4).ceilToDouble().clamp(1, double.infinity)),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(stats.length, (i) => BarChartGroupData(
          x: i,
          barRods: [BarChartRodData(
            toY: (stats[i].regeneratedEnergy ?? 0).toDouble(),
            color: _touched == i
                ? HyundaiColors.success.withValues(alpha: 0.6)
                : HyundaiColors.success,
            width: _barWidth(stats.length),
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4)),
          )],
        )),
      )),
    );
  }
}

// ── Energy tooltip helper ─────────────────────────────────────────────────────

List<TextSpan> _energySpans(DailyDrivingStat d) {
  String kw(int? v) => '${((v ?? 0) / 1000).toStringAsFixed(2)} kWh';
  TextSpan s(String t, Color c) =>
      TextSpan(text: t, style: TextStyle(color: c, fontSize: 11));
  return [
    s('Total: ${kw(d.totalConsumed)}\n',           Colors.white),
    s('Engine: ${kw(d.engineConsumption)}\n',       _colEngine),
    s('Climate: ${kw(d.climateConsumption)}\n',     _colClimate),
    s('Electronics: ${kw(d.electronicsConsumption)}\n', _colElectronics),
    s('Battery care: ${kw(d.batteryCareConsumption)}',  _colBatteryCare),
  ];
}

// ── Shared helpers ────────────────────────────────────────────────────────────

double _barWidth(int count) =>
    count <= 7 ? 22.0 : count <= 14 ? 14.0 : 8.0;

FlTitlesData _bottomLeft(
  ColorScheme cs,
  int count,
  String Function(int) bottomLabel,
  String Function(double) leftLabel, {
  required double interval,
}) =>
    FlTitlesData(
      leftTitles: AxisTitles(sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 42,
        interval: interval,
        getTitlesWidget: (v, _) => Text(leftLabel(v),
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10)),
      )),
      bottomTitles: AxisTitles(sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 28,
        interval: count <= 7 ? 1 : (count / 5).ceilToDouble(),
        getTitlesWidget: (v, _) {
          final i = v.toInt();
          if (i < 0 || i >= count) return const SizedBox();
          return Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(bottomLabel(i),
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10)),
          );
        },
      )),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );

FlGridData _grid(ColorScheme cs, double interval) => FlGridData(
      drawVerticalLine: false,
      horizontalInterval: interval,
      getDrawingHorizontalLine: (_) =>
          FlLine(color: cs.outlineVariant, strokeWidth: 0.5),
    );

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
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Wrap(spacing: 16, runSpacing: 6, children: [
      _Dot('Engine',       _colEngine,      cs),
      _Dot('Climate',      _colClimate,     cs),
      _Dot('Electronics',  _colElectronics, cs),
      _Dot('Battery care', _colBatteryCare, cs),
    ]);
  }
}

class _Dot extends StatelessWidget {
  final String label;
  final Color color;
  final ColorScheme cs;
  const _Dot(this.label, this.color, this.cs);
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10,
            decoration: BoxDecoration(color: color,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(
            color: cs.onSurfaceVariant, fontSize: 12)),
      ]);
}
