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
import 'package:markdown_tooltip/markdown_tooltip.dart';

import 'package:konapod/models/vehicle.dart';
import 'package:konapod/theme/hyundai_theme.dart';
import 'package:konapod/widgets/primitives.dart';

class FuelSection extends StatelessWidget {
  final Vehicle v;
  const FuelSection({super.key, required this.v});
  @override
  Widget build(BuildContext context) {
    final pct = v.fuelLevelPercent ?? 0;
    final barColor = pct < 15 ? HyundaiColors.error : HyundaiColors.warning;
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MarkdownTooltip(
            message: '**Fuel Level**\n\n'
                'Current fuel tank level as a percentage. '
                'Red below 15% indicates low fuel.\n\n'
                'The fuel gauge sensor reports this to the '
                'Body Control Module.',
            child: Row(
              children: [
                const Icon(
                  Icons.local_gas_station,
                  color: HyundaiColors.warning,
                  size: 20,
                ),
                const Gap(8),
                Text(
                  'Fuel',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                Text(
                  '${pct.round()}%',
                  style: TextStyle(
                    color: barColor,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const Gap(10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 10,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(barColor),
            ),
          ),
          if (v.fuelRangeKm != null) ...[
            const Gap(10),
            StatChip('Range', '${v.fuelRangeKm!.round()} km', Icons.route),
          ],
          if (v.isLowFuelWarning == true) ...[
            const Gap(8),
            const Row(
              children: [
                Icon(Icons.warning_amber, color: HyundaiColors.error, size: 16),
                Gap(6),
                Text(
                  'Low fuel warning',
                  style: TextStyle(color: HyundaiColors.error, fontSize: 13),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
