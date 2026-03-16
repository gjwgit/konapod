import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/vehicle.dart';
import '../services/app_provider.dart';
import '../theme/hyundai_theme.dart';
import '../widgets/daily_charts.dart';

/// Visuals screen — charts of daily driving statistics from the
/// currently displayed status snapshot.
class VisualsScreen extends StatelessWidget {
  const VisualsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vehicle = context.watch<AppProvider>().selectedVehicle;

    if (vehicle == null) {
      return _placeholder(context, 'No vehicle data loaded.',
          'Load a Bluelink snapshot or pod data first.');
    }

    final stats = vehicle.dailyStats;
    if (stats.isEmpty) {
      return _placeholder(context, 'No daily stats available.',
          'Daily driving statistics were not included in this snapshot.');
    }

    final hasEnergy = stats.any((d) => (d.totalConsumed ?? 0) > 0);
    final hasRegen = stats.any((d) => (d.regeneratedEnergy ?? 0) > 0);
    final total = stats.fold(0.0, (s, d) => s + d.distanceKm);
    final avg = total / stats.length;
    final best = stats.map((d) => d.distanceKm).reduce((a, b) => a > b ? a : b);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // ── Sub-header ────────────────────────────────────────────────
        Text('${stats.length} days · ${vehicle.nickname}',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13)),
        const SizedBox(height: 20),

        // ── Summary cards ─────────────────────────────────────────────
        _SummaryRow(total: total, avg: avg, best: best, days: stats.length),
        const SizedBox(height: 24),

        // ── Distance chart ────────────────────────────────────────────
        _ChartSection(
          title: 'Daily Distance Driven',
          subtitle: 'km per day',
          chart: DailyDistanceChart(stats: stats),
        ),
        const SizedBox(height: 24),

        // ── Energy consumption chart ──────────────────────────────────
        if (hasEnergy) ...[
          _ChartSection(
            title: 'Daily Energy Consumption',
            subtitle: 'kWh · coloured by type',
            chart: DailyEnergyChart(stats: stats),
          ),
          const SizedBox(height: 24),
        ],

        // ── Regenerated energy chart ──────────────────────────────────
        // if (hasRegen) ...[
        //   _ChartSection(
        //     title: 'Daily Regenerated Energy',
        //     subtitle: 'kWh recovered via regenerative braking',
        //     chart: DailyRegenChart(stats: stats),
        //   ),
        //   const SizedBox(height: 24),
        // ],

        // ── Detail table ──────────────────────────────────────────────
        _DetailTable(stats: stats, hasEnergy: hasEnergy, hasRegen: hasRegen),
        const SizedBox(height: 24),
      ]),
    );
  }

  Widget _placeholder(BuildContext context, String title, String sub) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.bar_chart,
                size: 64,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text(sub,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ]),
        ),
      );
}

// ── Summary row ───────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final double total, avg, best;
  final int days;
  const _SummaryRow(
      {required this.total,
      required this.avg,
      required this.best,
      required this.days});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(children: [
        _Cell('Total', '${total.toStringAsFixed(1)} km', cs),
        _Cell('Average', '${avg.toStringAsFixed(1)} km', cs),
        _Cell('Best day', '${best.toStringAsFixed(1)} km', cs),
        _Cell('Days', '$days', cs),
      ]),
    );
  }
}

class _Cell extends StatelessWidget {
  final String label, value;
  final ColorScheme cs;
  const _Cell(this.label, this.value, this.cs);
  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Text(label,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 13)),
        ]),
      );
}

// ── Chart section wrapper ─────────────────────────────────────────────────────

class _ChartSection extends StatelessWidget {
  final String title, subtitle;
  final Widget chart;
  const _ChartSection(
      {required this.title, required this.subtitle, required this.chart});
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 2),
        Text(subtitle,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12)),
        const SizedBox(height: 10),
        chart,
      ]);
}

// ── Detail table ──────────────────────────────────────────────────────────────

class _DetailTable extends StatelessWidget {
  final List<DailyDrivingStat> stats;
  final bool hasEnergy, hasRegen;
  const _DetailTable(
      {required this.stats, required this.hasEnergy, required this.hasRegen});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(children: [
            _Head('Date', cs),
            _Head('Dist', cs, align: TextAlign.right),
            if (hasEnergy) _Head('Consumed', cs, align: TextAlign.right),
            if (hasRegen) _Head('Regen', cs, align: TextAlign.right),
          ]),
        ),
        Divider(height: 1, color: cs.outlineVariant),
        ...stats.reversed.map((d) => Column(children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                child: Row(children: [
                  Expanded(
                      child: Text(DateFormat('EEE d MMM yy').format(d.date),
                          style: TextStyle(color: cs.onSurface, fontSize: 12))),
                  SizedBox(
                      width: 70,
                      child: Text('${d.distanceKm.toStringAsFixed(1)} km',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              color: HyundaiColors.accent,
                              fontWeight: FontWeight.w600,
                              fontSize: 12))),
                  if (hasEnergy)
                    SizedBox(
                        width: 80,
                        child: Text(
                            '${((d.totalConsumed ?? 0) / 1000).toStringAsFixed(2)} kWh',
                            textAlign: TextAlign.right,
                            style:
                                TextStyle(color: cs.onSurface, fontSize: 12))),
                  if (hasRegen)
                    SizedBox(
                        width: 72,
                        child: Text(
                            '${((d.regeneratedEnergy ?? 0) / 1000).toStringAsFixed(2)} kWh',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                                color: HyundaiColors.success,
                                fontWeight: FontWeight.w600,
                                fontSize: 12))),
                ]),
              ),
              Divider(
                  height: 1,
                  color: cs.outlineVariant,
                  indent: 16,
                  endIndent: 16),
            ])),
      ]),
    );
  }
}

class _Head extends StatelessWidget {
  final String text;
  final ColorScheme cs;
  final TextAlign align;
  const _Head(this.text, this.cs, {this.align = TextAlign.left});
  @override
  Widget build(BuildContext context) => Expanded(
      child: Text(text,
          textAlign: align,
          style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w600)));
}
