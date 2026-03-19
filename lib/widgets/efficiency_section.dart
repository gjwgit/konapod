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

import 'package:markdown_tooltip/markdown_tooltip.dart';

import 'package:konapod/models/vehicle.dart';

class EfficiencySection extends StatelessWidget {
  final Vehicle v;
  const EfficiencySection({super.key, required this.v});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final rows = [
      (
        'Overall',
        v.efficiencyOverall,
        '**Overall Efficiency**\n\n'
            'Your average energy consumption across *all* driving since the car '
            'was new, measured in kilowatt-hours per 100 km (kWh/100km).\n\n'
            'Lower is better — a smaller number means less energy used per km. '
            'The Kona EV has a WLTP-rated efficiency of around 15.7 kWh/100km. '
            'Real-world figures depend on driving style, speed, temperature '
            'and how much you use the climate system.',
      ),
      (
        'Since Charging',
        v.efficiencySinceCharging,
        '**Efficiency Since Last Charge**\n\n'
            'Your average energy consumption since the battery was last charged, '
            'in kWh/100km.\n\n'
            'This resets each time you charge and gives a useful snapshot of '
            'how efficiently you\'ve driven on the current charge cycle. '
            'Compare it to *Overall* to see if you\'re driving better or worse '
            'than your long-term average.',
      ),
      (
        'Latest Trip',
        v.efficiencyLatestTrip,
        '**Latest Trip Efficiency**\n\n'
            'Your energy consumption for the most recent trip, in kWh/100km.\n\n'
            'This resets at the start of each trip and gives the most immediate '
            'feedback on your driving style. '
            'Urban stop-start driving is often *more* efficient than highway '
            'driving because regenerative braking recovers energy each time '
            'you slow down.',
      ),
    ];
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
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: rows.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: cs.outlineVariant,
          indent: 16,
          endIndent: 16,
        ),
        itemBuilder: (_, i) {
          final (label, val, tip) = rows[i];
          return MarkdownTooltip(
            message: tip,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  // Fixed-width number so decimals align
                  SizedBox(
                    width: 36,
                    child: Text(
                      val != null ? val.toStringAsFixed(1) : '–',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  Text(
                    ' kWh/100km',
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
