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

import 'package:intl/intl.dart';

import 'package:konapod/models/vehicle.dart';
import 'package:konapod/theme/hyundai_theme.dart';
import 'package:konapod/widgets/stats/stat_card.dart';

// ── Overview card ─────────────────────────────────────────────────────────────

class OverviewCard extends StatelessWidget {
  final Vehicle vehicle;
  final List<DailyDrivingStat> stats;
  const OverviewCard({super.key, required this.vehicle, required this.stats});

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

    return statsCard(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          statsHeading(context, 'Overview'),
          statsSubheading(context, 'Distance · $dateRange · $days days'),
          StatsRow(
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
          StatsRow(
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
            StatsRow(
              'Odometer (total)',
              '${NumberFormat('#,##0').format(v.odometerKm!.round())} km',
              tooltip: '**Odometer**\n\n'
                  'Total distance the car has travelled since it left the factory, '
                  'including any distance driven before Bluelink was registered.',
            ),
          ],
          statsSubheading(context, 'Energy · since registration'),
          StatsRow(
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
          StatsRow(
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
          StatsRow(
            'Net consumed',
            '${net.toStringAsFixed(2)} kWh',
            bold: true,
            tooltip: '**Net Consumption (since registration)**\n\n'
                'Gross consumed minus regenerated. This is the true net energy '
                'drawn from the battery — what your efficiency figures are based on.',
          ),
          if (v.powerConsumption30dKwh != null) ...[
            statsSubheading(context, 'From Bluelink API'),
            StatsRow(
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
              StatsRow(
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
