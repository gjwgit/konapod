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

import 'package:konapod/models/daily_driving_stat.dart';
import 'package:konapod/models/vehicle.dart';
import 'package:konapod/widgets/stats/stat_card.dart';

// ── Breakdown card ────────────────────────────────────────────────────────────

class BreakdownCard extends StatelessWidget {
  final List<DailyDrivingStat> stats;
  const BreakdownCard({super.key, required this.stats});

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

    return statsCard(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          statsHeading(context, 'Energy Breakdown'),
          statsSubheading(context, 'Where the energy went'),
          if (engine > 0) ...[
            StatsRow(
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
            StatsRow(
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
            StatsRow(
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
            StatsRow(
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
          StatsRow('Total', '${total.toStringAsFixed(2)} kWh', bold: true),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
