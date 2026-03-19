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

import 'package:konapod/models/daily_driving_stat.dart';
import 'package:konapod/models/vehicle.dart';
import 'package:konapod/theme/hyundai_theme.dart';
import 'package:konapod/widgets/stats/stat_card.dart';

// ── Daily leaderboard ─────────────────────────────────────────────────────────

class DailyLeaderboard extends StatelessWidget {
  final List<DailyDrivingStat> stats;
  const DailyLeaderboard({super.key, required this.stats});

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

    return statsCard(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          statsHeading(context, 'Daily Leaderboard'),
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
