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
import 'package:markdown_tooltip/markdown_tooltip.dart';

import 'package:konapod/models/vehicle.dart';
import 'package:konapod/theme/hyundai_theme.dart';

// ── Consumption summary table ─────────────────────────────────────────────────

class ConsumptionSummary extends StatelessWidget {
  final Vehicle vehicle;
  final List<DailyDrivingStat> stats;
  const ConsumptionSummary({
    super.key,
    required this.vehicle,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final v = vehicle;

    final totalDist = v.statsTotalDistanceKm;
    final totalConsumed = v.statsTotalConsumedKwh;
    final totalRegen = v.statsTotalRegenKwh;
    final netConsumed = v.statsNetConsumedKwh;
    final avgEff = v.statsAvgEfficiency;
    final best = v.statsBestDay;
    final worst = v.statsWorstDay;

    final dfmt = DateFormat('d MMM yyyy');
    final firstDate = stats.isNotEmpty ? dfmt.format(stats.first.date) : '–';
    final lastDate = stats.isNotEmpty ? dfmt.format(stats.last.date) : '–';
    final dateRange = '$firstDate – $lastDate';

    // Breakdown totals from daily stats (Wh → kWh)
    final engineKwh =
        stats.fold(0.0, (s, d) => s + (d.engineConsumption ?? 0)) / 1000;
    final climateKwh =
        stats.fold(0.0, (s, d) => s + (d.climateConsumption ?? 0)) / 1000;
    final electronicsKwh =
        stats.fold(0.0, (s, d) => s + (d.electronicsConsumption ?? 0)) / 1000;
    final batteryCareKwh =
        stats.fold(0.0, (s, d) => s + (d.batteryCareConsumption ?? 0)) / 1000;

    final fmt = DateFormat('EEE d MMM');

    Widget row(
      String label,
      String value, {
      Color? valueColor,
      bool bold = false,
    }) =>
        Padding(
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

    Widget divider() =>
        Divider(height: 1, color: cs.outlineVariant, indent: 16, endIndent: 16);

    Widget heading(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: Text(
            text.toUpperCase(),
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
        );

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: MarkdownTooltip(
              message: '**Consumption Summary**\n\n'
                  'Aggregated energy statistics across all daily driving data.\n\n'
                  'Shows total distance, gross consumption, regenerated energy, '
                  'net consumption, and the breakdown by subsystem '
                  '(drive motor, climate, electronics, battery care).\n\n'
                  'Best and worst days are ranked by net efficiency (kWh/100km).',
              child: Text(
                'Consumption Summary',
                style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          Divider(height: 1, color: cs.outlineVariant),

          // Distance & energy totals
          heading('Since registration  ·  $dateRange  ·  ${stats.length} days'),
          row('Distance', '${totalDist.toStringAsFixed(1)} km'),
          divider(),
          row('Consumed', '${totalConsumed.toStringAsFixed(2)} kWh'),
          divider(),
          row(
            'Regenerated',
            '− ${totalRegen.toStringAsFixed(2)} kWh',
            valueColor: HyundaiColors.success,
          ),
          divider(),
          row(
            'Net Consumed',
            '${netConsumed.toStringAsFixed(2)} kWh',
            bold: true,
          ),

          // Breakdown
          if (engineKwh > 0 ||
              climateKwh > 0 ||
              electronicsKwh > 0 ||
              batteryCareKwh > 0) ...[
            heading('Breakdown'),
            if (engineKwh > 0) ...[
              row('Drive (motor)', '${engineKwh.toStringAsFixed(2)} kWh'),
              divider(),
            ],
            if (climateKwh > 0) ...[
              row('Climate', '${climateKwh.toStringAsFixed(2)} kWh'),
              divider(),
            ],
            if (electronicsKwh > 0) ...[
              row('Electronics', '${electronicsKwh.toStringAsFixed(2)} kWh'),
              divider(),
            ],
            if (batteryCareKwh > 0) ...[
              row('Battery care', '${batteryCareKwh.toStringAsFixed(2)} kWh'),
              divider(),
            ],
          ],

          // Efficiency
          heading('Efficiency'),
          if (avgEff != null) ...[
            row(
              'Average (net)',
              '${avgEff.toStringAsFixed(1)} kWh/100km',
              bold: true,
            ),
            divider(),
          ],
          if (best != null) ...[
            row(
              'Best day  ${fmt.format(best.date)}',
              '${best.netEfficiencyKwhPer100km.toStringAsFixed(1)} kWh/100km',
              valueColor: HyundaiColors.success,
            ),
            divider(),
          ],
          if (worst != null)
            row(
              'Worst day  ${fmt.format(worst.date)}',
              '${worst.netEfficiencyKwhPer100km.toStringAsFixed(1)} kWh/100km',
              valueColor: HyundaiColors.warning,
            ),

          // API lifetime totals
          if (v.totalPowerConsumedKwh != null ||
              v.powerConsumption30dKwh != null) ...[
            heading('From Bluelink API'),
            if (v.powerConsumption30dKwh != null) ...[
              row(
                'Last 30 days',
                '${v.powerConsumption30dKwh!} kWh',
              ),
              divider(),
            ],
            if (v.totalPowerConsumedKwh != null)
              row(
                'Lifetime total',
                '${v.totalPowerConsumedKwh!} kWh',
              ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
