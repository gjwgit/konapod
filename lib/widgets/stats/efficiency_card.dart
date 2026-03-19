/// DoorsSection widget showing lock, engine, charging and door states.
///
// Time-stamp: <Wednesday 2026-03-18 09:56:35 +1100 Graham Williams>
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

import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import 'package:konapod/models/vehicle.dart';
import 'package:konapod/theme/hyundai_theme.dart';
import 'package:konapod/widgets/stats/stat_card.dart';

// ── Efficiency card ───────────────────────────────────────────────────────────

class EfficiencyCard extends StatelessWidget {
  final Vehicle vehicle;
  final List<DailyDrivingStat> stats;
  const EfficiencyCard({super.key, required this.vehicle, required this.stats});

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

    return statsCard(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          statsHeading(context, 'Efficiency'),
          statsSubheading(
            context,
            'Net kWh/100km since registration · consumed − regenerated',
          ),
          if (avgEff != null) ...[
            StatsRow(
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
            StatsRow(
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
            StatsRow(
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
            StatsRow(
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
            statsSubheading(
              context,
              'Day distribution (${driving.length} driving days)',
            ),
            BandBar(
              label: '< 14  Excellent',
              count: excellent,
              total: driving.length,
              color: HyundaiColors.success,
            ),
            const Gap(4),
            BandBar(
              label: '14–17  Good',
              count: good,
              total: driving.length,
              color: HyundaiColors.accent,
            ),
            const Gap(4),
            BandBar(
              label: '17–20  Fair',
              count: fair,
              total: driving.length,
              color: HyundaiColors.warning,
            ),
            const Gap(4),
            BandBar(
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

class BandBar extends StatelessWidget {
  final String label;
  final int count, total;
  final Color color;
  const BandBar({
    super.key,
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
