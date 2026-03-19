/// StatsScreen — historical consumption and driving statistics.
///
// Time-stamp: <Thursday 2026-03-19 00:00:00 +1100 Graham Williams>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://opensource.org/license/gpl-3-0
//
// This program is free software: you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by the Free
// Software Foundation, either version 3 of the License, or (at your option)
// any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
// details.
//
// You should have received a copy of the GNU General Public License along with
// this program. If not, see <https://opensource.org/license/gpl-3-0>.
///
/// Authors: Claude, Graham Williams

library;

import 'package:flutter/material.dart';

import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:markdown_tooltip/markdown_tooltip.dart';
import 'package:provider/provider.dart';

import 'package:konapod/models/vehicle.dart';
import 'package:konapod/services/app_provider.dart';
import 'package:konapod/theme/hyundai_theme.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final vehicle = provider.selectedVehicle;

    if (vehicle == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.query_stats,
                size: 64,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withValues(alpha: 0.3),
              ),
              const Gap(16),
              const Text(
                'No vehicle data',
                style: TextStyle(fontSize: 16),
              ),
              const Gap(8),
              Text(
                'Load data from Bluelink or your Solid Pod to see statistics.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final stats = vehicle.dailyStats;
    if (stats.isEmpty) {
      return const Center(
        child: Text('No daily statistics available.'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _OverviewCard(vehicle: vehicle, stats: stats),
          const Gap(16),
          _EfficiencyCard(vehicle: vehicle, stats: stats),
          const Gap(16),
          _BreakdownCard(stats: stats),
          const Gap(16),
          _DailyLeaderboard(stats: stats),
          const Gap(24),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Widget _card({required BuildContext context, required Widget child}) =>
    Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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

Widget _heading(BuildContext context, String text) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Text(
        text,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    );

Widget _subheading(BuildContext context, String text) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
    );

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;
  final String? tooltip;

  const _StatRow(
    this.label,
    this.value, {
    this.valueColor,
    this.bold = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 13,
                fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? cs.onSurface,
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
    if (tooltip == null) return row;
    return MarkdownTooltip(message: tooltip!, child: row);
  }
}

// ── Overview card ─────────────────────────────────────────────────────────────

class _OverviewCard extends StatelessWidget {
  final Vehicle vehicle;
  final List<DailyDrivingStat> stats;
  const _OverviewCard({required this.vehicle, required this.stats});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final v = vehicle;
    final totalDist = v.statsTotalDistanceKm;
    final consumed = v.statsTotalConsumedKwh;
    final regen = v.statsTotalRegenKwh;
    final net = v.statsNetConsumedKwh;
    final days = stats.length;
    final avgDist = days > 0 ? totalDist / days : 0.0;

    final fmt = DateFormat('d MMM yyyy');
    final firstDate = stats.isNotEmpty ? fmt.format(stats.first.date) : '–';
    final lastDate = stats.isNotEmpty ? fmt.format(stats.last.date) : '–';
    final dateRange = '$firstDate – $lastDate';

    return _card(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _heading(context, 'Overview'),
          _subheading(context, 'Distance · $dateRange · $days days'),
          _StatRow(
            'Since registration',
            '${totalDist.toStringAsFixed(1)} km',
            tooltip: '**Distance Since Registration**\n\n'
                'Sum of all distances recorded in the daily stats. '
                'Bluelink only began recording on the registration date, '
                'so this will be less than the odometer if the car was '
                'driven before Bluelink was set up.',
          ),
          Divider(
            height: 1,
            color: cs.outlineVariant,
            indent: 16,
            endIndent: 16,
          ),
          _StatRow(
            'Average per day',
            '${avgDist.toStringAsFixed(1)} km',
            tooltip:
                '**Average Daily Distance**\n\nTotal distance ÷ number of days.',
          ),
          if (v.odometerKm != null) ...[
            Divider(
              height: 1,
              color: cs.outlineVariant,
              indent: 16,
              endIndent: 16,
            ),
            _StatRow(
              'Odometer (total)',
              '${NumberFormat('#,##0').format(v.odometerKm!.round())} km',
              tooltip: '**Odometer**\n\n'
                  'Total distance the car has travelled since it left the factory, '
                  'including any distance driven before Bluelink was registered.',
            ),
          ],
          _subheading(context, 'Energy · since registration'),
          _StatRow(
            'Consumed (gross)',
            '${consumed.toStringAsFixed(2)} kWh',
            tooltip: '**Gross Consumption (since registration)**\n\n'
                'Total energy drawn from the battery across all recorded days. '
                'Does not include any energy used before the registration date.',
          ),
          Divider(
            height: 1,
            color: cs.outlineVariant,
            indent: 16,
            endIndent: 16,
          ),
          _StatRow(
            'Regenerated',
            '− ${regen.toStringAsFixed(2)} kWh',
            valueColor: HyundaiColors.success,
            tooltip: '**Regenerated Energy (since registration)**\n\n'
                'Energy recovered via regenerative braking and returned to the '
                'battery. The motor acts as a generator when you slow down, '
                'converting kinetic energy back into electricity.',
          ),
          Divider(
            height: 1,
            color: cs.outlineVariant,
            indent: 16,
            endIndent: 16,
          ),
          _StatRow(
            'Net consumed',
            '${net.toStringAsFixed(2)} kWh',
            bold: true,
            tooltip: '**Net Consumption (since registration)**\n\n'
                'Gross consumed minus regenerated. This is the true net energy '
                'drawn from the battery — what your efficiency figures are based on.',
          ),
          if (v.powerConsumption30dKwh != null) ...[
            _subheading(context, 'From Bluelink API'),
            _StatRow(
              'Last 30 days',
              '${v.powerConsumption30dKwh!} kWh',
              tooltip: '**Last 30 Days (API)**\n\n'
                  'Total energy consumed over the past 30 days as reported '
                  'directly by the Bluelink API.',
            ),
            if (v.totalPowerConsumedKwh != null) ...[
              Divider(
                height: 1,
                color: cs.outlineVariant,
                indent: 16,
                endIndent: 16,
              ),
              _StatRow(
                'Lifetime total',
                '${v.totalPowerConsumedKwh!} kWh',
                tooltip: '**Lifetime Total (API)**\n\n'
                    'Cumulative energy consumed since the car was new, '
                    'as reported by Bluelink.',
              ),
            ],
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Efficiency card ───────────────────────────────────────────────────────────

class _EfficiencyCard extends StatelessWidget {
  final Vehicle vehicle;
  final List<DailyDrivingStat> stats;
  const _EfficiencyCard({required this.vehicle, required this.stats});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final v = vehicle;
    final avgEff = v.statsAvgEfficiency;
    final best = v.statsBestDay;
    final worst = v.statsWorstDay;
    final fmt = DateFormat('EEE d MMM');

    // Percentile distribution: count days by efficiency band
    final driving = stats.where((d) => d.distanceKm > 0).toList();
    final excellent =
        driving.where((d) => d.netEfficiencyKwhPer100km < 14).length;
    final good = driving
        .where(
          (d) =>
              d.netEfficiencyKwhPer100km >= 14 &&
              d.netEfficiencyKwhPer100km < 17,
        )
        .length;
    final fair = driving
        .where(
          (d) =>
              d.netEfficiencyKwhPer100km >= 17 &&
              d.netEfficiencyKwhPer100km < 20,
        )
        .length;
    final poor = driving.where((d) => d.netEfficiencyKwhPer100km >= 20).length;

    return _card(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _heading(context, 'Efficiency'),
          _subheading(
            context,
            'Net kWh/100km since registration · consumed − regenerated',
          ),
          if (avgEff != null) ...[
            _StatRow(
              'Average',
              '${avgEff.toStringAsFixed(1)} kWh/100km',
              bold: true,
              tooltip: '**Average Net Efficiency**\n\n'
                  'Net energy consumed per 100 km across all recorded days.\n\n'
                  'Lower is better. The Kona EV\'s WLTP rating is ~15.7 kWh/100km. '
                  'Real-world figures of 14–18 kWh/100km are typical depending on '
                  'speed, temperature and driving style.',
            ),
            Divider(
              height: 1,
              color: cs.outlineVariant,
              indent: 16,
              endIndent: 16,
            ),
          ],
          if (v.efficiencyOverall != null) ...[
            _StatRow(
              'Lifetime (Bluelink)',
              '${v.efficiencyOverall!.toStringAsFixed(1)} kWh/100km',
              tooltip: '**Lifetime Efficiency (Bluelink API)**\n\n'
                  'Long-run average reported by the car\'s onboard computer '
                  'across all driving since new.',
            ),
            Divider(
              height: 1,
              color: cs.outlineVariant,
              indent: 16,
              endIndent: 16,
            ),
          ],
          if (best != null) ...[
            _StatRow(
              'Best  ${fmt.format(best.date)}',
              '${best.netEfficiencyKwhPer100km.toStringAsFixed(1)} kWh/100km',
              valueColor: HyundaiColors.success,
              tooltip:
                  '**Best Day**\n\nThe most energy-efficient day in the dataset.\n\n'
                  'Low-speed urban driving with frequent regenerative braking '
                  'typically produces the best efficiency figures.',
            ),
            Divider(
              height: 1,
              color: cs.outlineVariant,
              indent: 16,
              endIndent: 16,
            ),
          ],
          if (worst != null) ...[
            _StatRow(
              'Worst  ${fmt.format(worst.date)}',
              '${worst.netEfficiencyKwhPer100km.toStringAsFixed(1)} kWh/100km',
              valueColor: HyundaiColors.warning,
              tooltip:
                  '**Worst Day**\n\nThe least energy-efficient day in the dataset.\n\n'
                  'Highway driving at speed, cold weather, and heavy climate '
                  'use all increase energy consumption per km.',
            ),
          ],
          if (driving.isNotEmpty) ...[
            _subheading(
              context,
              'Day distribution (${driving.length} driving days)',
            ),
            _BandBar(
              label: '< 14  Excellent',
              count: excellent,
              total: driving.length,
              color: HyundaiColors.success,
            ),
            const Gap(4),
            _BandBar(
              label: '14–17  Good',
              count: good,
              total: driving.length,
              color: HyundaiColors.accent,
            ),
            const Gap(4),
            _BandBar(
              label: '17–20  Fair',
              count: fair,
              total: driving.length,
              color: HyundaiColors.warning,
            ),
            const Gap(4),
            _BandBar(
              label: '≥ 20   Poor',
              count: poor,
              total: driving.length,
              color: HyundaiColors.error,
            ),
          ],
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}

class _BandBar extends StatelessWidget {
  final String label;
  final int count, total;
  final Color color;
  const _BandBar({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final frac = total == 0 ? 0.0 : count / total;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: frac,
                minHeight: 8,
                backgroundColor: cs.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const Gap(8),
          SizedBox(
            width: 28,
            child: Text(
              '$count',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: count > 0 ? color : cs.onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Breakdown card ────────────────────────────────────────────────────────────

class _BreakdownCard extends StatelessWidget {
  final List<DailyDrivingStat> stats;
  const _BreakdownCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final engine =
        stats.fold(0.0, (s, d) => s + (d.engineConsumption ?? 0)) / 1000;
    final climate =
        stats.fold(0.0, (s, d) => s + (d.climateConsumption ?? 0)) / 1000;
    final electronics =
        stats.fold(0.0, (s, d) => s + (d.electronicsConsumption ?? 0)) / 1000;
    final batteryCare =
        stats.fold(0.0, (s, d) => s + (d.batteryCareConsumption ?? 0)) / 1000;
    final total = engine + climate + electronics + batteryCare;

    if (total == 0) return const SizedBox.shrink();

    String pct(double v) =>
        total > 0 ? ' (${(v / total * 100).toStringAsFixed(0)}%)' : '';

    return _card(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _heading(context, 'Energy Breakdown'),
          _subheading(context, 'Where the energy went'),
          if (engine > 0) ...[
            _StatRow(
              'Drive (motor)',
              '${engine.toStringAsFixed(2)} kWh${pct(engine)}',
              tooltip: '**Drive (Motor)**\n\n'
                  'Energy used to propel the car — turning the wheels via the '
                  'electric motor. This is the dominant consumer in most conditions.',
            ),
            Divider(
              height: 1,
              color: cs.outlineVariant,
              indent: 16,
              endIndent: 16,
            ),
          ],
          if (climate > 0) ...[
            _StatRow(
              'Climate',
              '${climate.toStringAsFixed(2)} kWh${pct(climate)}',
              valueColor: const Color(0xFF00B4D8),
              tooltip: '**Climate Control**\n\n'
                  'Energy used by the heating and air conditioning system. '
                  'This can be a significant proportion in extreme weather — '
                  'heating in winter is particularly energy-intensive on EVs '
                  'as there is no waste engine heat to use.',
            ),
            Divider(
              height: 1,
              color: cs.outlineVariant,
              indent: 16,
              endIndent: 16,
            ),
          ],
          if (electronics > 0) ...[
            _StatRow(
              'Electronics',
              '${electronics.toStringAsFixed(2)} kWh${pct(electronics)}',
              tooltip: '**Onboard Electronics**\n\n'
                  'Energy used by the car\'s electrical systems — infotainment, '
                  'lighting, power steering, instrument cluster, cameras and '
                  'other auxiliary loads.',
            ),
            Divider(
              height: 1,
              color: cs.outlineVariant,
              indent: 16,
              endIndent: 16,
            ),
          ],
          if (batteryCare > 0) ...[
            _StatRow(
              'Battery care',
              '${batteryCare.toStringAsFixed(2)} kWh${pct(batteryCare)}',
              tooltip: '**Battery Care**\n\n'
                  'Energy used by the battery management system (BMS) for '
                  'thermal regulation — heating or cooling the battery pack '
                  'to keep it within its optimal operating temperature range. '
                  'Protects battery longevity but consumes a small amount of energy.',
            ),
            Divider(
              height: 1,
              color: cs.outlineVariant,
              indent: 16,
              endIndent: 16,
            ),
          ],
          _StatRow('Total', '${total.toStringAsFixed(2)} kWh', bold: true),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Daily leaderboard ─────────────────────────────────────────────────────────

class _DailyLeaderboard extends StatelessWidget {
  final List<DailyDrivingStat> stats;
  const _DailyLeaderboard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fmt = DateFormat('EEE d MMM');

    final driving = stats
        .where((d) => d.distanceKm > 0 && (d.totalConsumed ?? 0) > 0)
        .toList()
      ..sort(
        (a, b) =>
            a.netEfficiencyKwhPer100km.compareTo(b.netEfficiencyKwhPer100km),
      );

    if (driving.isEmpty) return const SizedBox.shrink();

    return _card(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _heading(context, 'Daily Leaderboard'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                const SizedBox(width: 24),
                Expanded(
                  child: Text(
                    'Date',
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Text(
                    'km',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: Text(
                    'kWh/100km',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outlineVariant),
          ...driving.asMap().entries.map((entry) {
            final i = entry.key;
            final d = entry.value;
            final eff = d.netEfficiencyKwhPer100km;
            final color = eff < 14
                ? HyundaiColors.success
                : eff < 17
                    ? HyundaiColors.accent
                    : eff < 20
                        ? HyundaiColors.warning
                        : HyundaiColors.error;
            final medal = i == 0
                ? '🥇'
                : i == 1
                    ? '🥈'
                    : i == 2
                        ? '🥉'
                        : '  ';
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        child: Text(
                          medal,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          fmt.format(d.date),
                          style: TextStyle(color: cs.onSurface, fontSize: 12),
                        ),
                      ),
                      SizedBox(
                        width: 60,
                        child: Text(
                          d.distanceKm.toStringAsFixed(1),
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        child: Text(
                          eff.toStringAsFixed(1),
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < driving.length - 1)
                  Divider(
                    height: 1,
                    color: cs.outlineVariant,
                    indent: 40,
                    endIndent: 16,
                  ),
              ],
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
