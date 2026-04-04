/// DrivingHeroCard — gradient summary card for the DRIVING tab, styled to
/// match the Battery hero card on the ENERGY tab.
///
// Time-stamp: <Friday 2026-04-04 12:00:00 +1100 Graham Williams>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://opensource.org/license/gpl-3-0

library;

import 'package:flutter/material.dart';

import 'package:gap/gap.dart';
import 'package:markdown_tooltip/markdown_tooltip.dart';

import 'package:konapod/models/daily_driving_stat.dart';
import 'package:konapod/models/vehicle.dart';
import 'package:konapod/theme/hyundai_theme.dart';

class DrivingHeroCard extends StatelessWidget {
  final Vehicle vehicle;
  final List<DailyDrivingStat> stats;

  const DrivingHeroCard({
    super.key,
    required this.vehicle,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final total = vehicle.statsTotalDistanceKm;
    final avg = stats.isNotEmpty ? total / stats.length : 0.0;
    final median = _computeMedian(stats);
    final best =
        stats.isNotEmpty
            ? stats.map((d) => d.distanceKm).reduce((a, b) => a > b ? a : b)
            : 0.0;
    final hasEnergy = stats.any((d) => (d.totalConsumed ?? 0) > 0);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [HyundaiColors.primary, Color(0xFF7A5C44)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: HyundaiColors.primary.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Row(
            children: [
              const Icon(Icons.route, color: Colors.white70, size: 20),
              const Gap(8),
              const Text(
                'Driving',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  letterSpacing: 0.3,
                ),
              ),
              const Gap(12),
              Text(
                '${stats.length} days · ${vehicle.nickname}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Text(
                '${total.toStringAsFixed(0)} km',
                style: const TextStyle(
                  color: HyundaiColors.accent,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const Gap(14),

          // ── Distance stats ──────────────────────────────────────────────
          Wrap(
            spacing: 20,
            runSpacing: 8,
            children: [
              _Chip(
                'Total',
                '${total.toStringAsFixed(1)} km',
                Icons.straighten,
                tooltip: '**Total Distance**\n\n'
                    'The sum of all daily distances across '
                    'the ${stats.length} days of driving data.',
              ),
              _Chip(
                'Average',
                '${avg.toStringAsFixed(1)} km/day',
                Icons.trending_flat,
                tooltip: '**Average Daily Distance**\n\n'
                    'Total distance divided by the number of days '
                    'with recorded driving data.',
              ),
              _Chip(
                'Median',
                '${median.toStringAsFixed(1)} km/day',
                Icons.align_vertical_center,
                tooltip: '**Median Daily Distance**\n\n'
                    'The middle value when all daily distances are '
                    'sorted. Less affected by outliers than the average — '
                    'if the median is much lower than the average, '
                    'a few long trips are pulling the average up.',
              ),
              _Chip(
                'Furthest',
                '${best.toStringAsFixed(1)} km',
                Icons.emoji_events,
                tooltip: '**Longest Single Day**\n\n'
                    'The most kilometres driven in a single day.',
              ),
              _Chip(
                'Days',
                '${stats.length}',
                Icons.calendar_today,
                tooltip: '**Days of Data**\n\n'
                    'The number of days with driving activity '
                    'in the current dataset.',
              ),
            ],
          ),

          // ── Energy stats (if available) ─────────────────────────────────
          if (hasEnergy) ...[
            const Gap(12),
            Divider(
              height: 1,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            const Gap(10),
            Row(
              children: [
                const Text(
                  'Energy',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: Wrap(
                    spacing: 20,
                    runSpacing: 8,
                    children: [
                      _Chip(
                        'Consumed',
                        '${vehicle.statsTotalConsumedKwh.toStringAsFixed(1)} kWh',
                        Icons.electric_meter,
                        tooltip: '**Total Energy Consumed**\n\n'
                            'The gross energy drawn from the battery across '
                            'all days, in kilowatt-hours.',
                      ),
                      _Chip(
                        'Regenerated',
                        '${vehicle.statsTotalRegenKwh.toStringAsFixed(1)} kWh',
                        Icons.recycling,
                        tooltip: '**Total Regenerated Energy**\n\n'
                            'Energy recovered through regenerative braking '
                            'and fed back into the battery.',
                        color: HyundaiColors.success,
                      ),
                      _Chip(
                        'Net',
                        '${vehicle.statsNetConsumedKwh.toStringAsFixed(1)} kWh',
                        Icons.bolt,
                        tooltip: '**Net Consumption**\n\n'
                            'Consumed minus regenerated — the actual energy '
                            'taken from the grid to cover all driving.',
                      ),
                      if (vehicle.statsAvgEfficiency != null)
                        _Chip(
                          'Efficiency',
                          '${vehicle.statsAvgEfficiency!.toStringAsFixed(1)} kWh/100km',
                          Icons.speed,
                          tooltip: '**Average Net Efficiency**\n\n'
                              'Net consumption per 100 km across all days.\n\n'
                              'Lower is better. The Kona EV typically achieves '
                              '13–16 kWh/100km depending on driving style '
                              'and conditions.',
                        ),
                      if (_dailyMedianEfficiency(stats) != null)
                        _Chip(
                          'Daily Median',
                          '${_dailyMedianEfficiency(stats)!.toStringAsFixed(1)} kWh/100km',
                          Icons.bar_chart,
                          tooltip: '**Daily Median Efficiency**\n\n'
                              'The median of each day\'s individual efficiency '
                              '(kWh/100km), only counting days with driving.\n\n'
                              'The median is less affected by outliers than '
                              'the mean — a single unusually short or long trip '
                              'won\'t skew the figure. It represents your '
                              '"typical day" efficiency.',
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Median helper ────────────────────────────────────────────────────────────

double _computeMedian(List<DailyDrivingStat> stats) {
  if (stats.isEmpty) return 0;
  final sorted = stats.map((d) => d.distanceKm).toList()..sort();
  final mid = sorted.length ~/ 2;

  return sorted.length.isOdd
      ? sorted[mid]
      : (sorted[mid - 1] + sorted[mid]) / 2;
}

/// Median of each day's individual net efficiency, excluding zero-distance days.

double? _dailyMedianEfficiency(List<DailyDrivingStat> stats) {
  final values = stats
      .where((d) => d.distanceKm > 0)
      .map((d) => d.netEfficiencyKwhPer100km)
      .toList()
    ..sort();
  if (values.isEmpty) return null;
  final mid = values.length ~/ 2;

  return values.length.isOdd
      ? values[mid]
      : (values[mid - 1] + values[mid]) / 2;
}

// ── Hero chip (white-on-dark, matching BatterySection style) ─────────────────

class _Chip extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color? color;
  final String? tooltip;

  const _Chip(this.label, this.value, this.icon, {this.tooltip, this.color});

  @override
  Widget build(BuildContext context) {
    final chip = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color ?? Colors.white60),
        const Gap(4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 10),
            ),
            Text(
              value,
              style: TextStyle(
                color: color ?? Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
    if (tooltip == null) return chip;

    return MarkdownTooltip(message: tooltip!, child: chip);
  }
}
