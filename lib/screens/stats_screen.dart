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
import 'package:konapod/widgets/stats/breakdown_card.dart';
import 'package:konapod/widgets/stats/daily_leaderboard.dart';
import 'package:konapod/widgets/stats/efficiency_card.dart';
import 'package:konapod/widgets/stats/overview_card.dart';

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
          OverviewCard(vehicle: vehicle, stats: stats),
          const Gap(16),
          EfficiencyCard(vehicle: vehicle, stats: stats),
          const Gap(16),
          BreakdownCard(stats: stats),
          const Gap(16),
          DailyLeaderboard(stats: stats),
          const Gap(24),
        ],
      ),
    );
  }
}
