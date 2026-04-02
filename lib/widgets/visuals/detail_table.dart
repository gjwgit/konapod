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

// ── Detail table ──────────────────────────────────────────────────────────────

class DetailTable extends StatelessWidget {
  final List<DailyDrivingStat> stats;
  final bool hasEnergy, hasRegen;
  const DetailTable({
    super.key,
    required this.stats,
    required this.hasEnergy,
    required this.hasRegen,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return IntrinsicWidth(
      child: Container(
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
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 120,
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
                    width: 70,
                    child: Text(
                      'Dist',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (hasEnergy)
                    SizedBox(
                      width: 80,
                      child: Text(
                        'Consumed',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (hasRegen)
                    SizedBox(
                      width: 72,
                      child: Text(
                        'Regen',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (hasRegen && hasEnergy)
                    SizedBox(
                      width: 62,
                      child: Text(
                        'Regen %',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (hasEnergy)
                    SizedBox(
                      width: 82,
                      child: Text(
                        'Efficiency',
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
            ...stats.reversed.map(
              (d) => Column(
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(
                            DateFormat('EEE d MMM yy').format(d.date),
                            style: TextStyle(color: cs.onSurface, fontSize: 12),
                          ),
                        ),
                        SizedBox(
                          width: 70,
                          child: Text(
                            '${d.distanceKm.toStringAsFixed(1)} km',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: HyundaiColors.accent,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        if (hasEnergy)
                          SizedBox(
                            width: 80,
                            child: Text(
                              '${((d.totalConsumed ?? 0) / 1000).toStringAsFixed(2)} kWh',
                              textAlign: TextAlign.right,
                              style:
                                  TextStyle(color: cs.onSurface, fontSize: 12),
                            ),
                          ),
                        if (hasRegen)
                          SizedBox(
                            width: 72,
                            child: Text(
                              '${((d.regeneratedEnergy ?? 0) / 1000).toStringAsFixed(2)} kWh',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                color: HyundaiColors.success,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        if (hasRegen && hasEnergy)
                          SizedBox(
                            width: 62,
                            child: Text(
                              (d.totalConsumed ?? 0) > 0
                                  ? '${_regenPercent(d).toStringAsFixed(0)}%'
                                  : '—',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                color: HyundaiColors.success,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        if (hasEnergy)
                          SizedBox(
                            width: 82,
                            child: Text(
                              d.distanceKm > 0
                                  ? _efficiency(d).toStringAsFixed(1)
                                  : '—',
                              textAlign: TextAlign.right,
                              style:
                                  TextStyle(color: cs.onSurface, fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: cs.outlineVariant,
                    indent: 16,
                    endIndent: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Net consumed energy per 100 km: (consumed − regen) / distance × 100.
///
/// Values from the API are in Wh; result is in kWh/100 km.

double _efficiency(DailyDrivingStat d) {
  final netWh = (d.totalConsumed ?? 0) - (d.regeneratedEnergy ?? 0);

  return (netWh / 1000) / d.distanceKm * 100;
}

/// Regenerated energy as a percentage of total consumed.

double _regenPercent(DailyDrivingStat d) {
  return (d.regeneratedEnergy ?? 0) / (d.totalConsumed ?? 1) * 100;
}

// ── Consumption summary table ─────────────────────────────────────────────────
