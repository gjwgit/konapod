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
import 'package:provider/provider.dart';

import 'package:konapod/services/app_provider.dart';
import 'package:konapod/widgets/daily_charts.dart';
import 'package:konapod/widgets/visuals/chart_section.dart';
import 'package:konapod/widgets/visuals/consumption_summary.dart';
import 'package:konapod/widgets/visuals/detail_table.dart';
import 'package:konapod/widgets/visuals/summary_row.dart';

class VisualsScreen extends StatelessWidget {
  const VisualsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vehicle = context.watch<AppProvider>().selectedVehicle;

    if (vehicle == null) {
      return _placeholder(
        context,
        'No vehicle data loaded.',
        'Load a Bluelink snapshot or pod data first.',
      );
    }

    final stats = vehicle.dailyStats;
    if (stats.isEmpty) {
      return _placeholder(
        context,
        'No daily stats available.',
        'Daily driving statistics were not included in this snapshot.',
      );
    }

    final hasEnergy = stats.any((d) => (d.totalConsumed ?? 0) > 0);
    final hasRegen = stats.any((d) => (d.regeneratedEnergy ?? 0) > 0);
    final total = stats.fold(0.0, (s, d) => s + d.distanceKm);
    final avg = total / stats.length;
    final best = stats.map((d) => d.distanceKm).reduce((a, b) => a > b ? a : b);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Sub-header ────────────────────────────────────────────────
          Text(
            '${stats.length} days · ${vehicle.nickname}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          const Gap(20),

          // ── Summary cards ─────────────────────────────────────────────
          SummaryRow(total: total, avg: avg, best: best, days: stats.length),
          const Gap(24),

          // ── Distance chart ────────────────────────────────────────────
          ChartSection(
            title: 'Daily Distance Driven',
            subtitle: 'km per day',
            chart: DailyDistanceChart(stats: stats),
          ),
          const Gap(24),

          // ── Energy consumption chart ──────────────────────────────────
          if (hasEnergy) ...[
            ChartSection(
              title: 'Daily Energy Consumption',
              subtitle:
                  'kWh · coloured by type · bar label is net (consumed − regenerated)',
              chart: DailyEnergyChart(stats: stats),
            ),
            const Gap(24),
          ],

          // ── Detail table ──────────────────────────────────────────────
          DetailTable(stats: stats, hasEnergy: hasEnergy, hasRegen: hasRegen),
          const Gap(24),

          // ── Consumption summary ───────────────────────────────────────
          if (hasEnergy) ...[
            ConsumptionSummary(vehicle: vehicle, stats: stats),
            const Gap(24),
          ],
        ],
      ),
    );
  }

  Widget _placeholder(BuildContext context, String title, String sub) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.bar_chart,
                size: 64,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withValues(alpha: 0.3),
              ),
              const Gap(16),
              Text(title, style: const TextStyle(fontSize: 16)),
              const Gap(8),
              Text(
                sub,
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
