/// WarningsSection widget listing all active vehicle warnings.
///
// Time-stamp: <Monday 2026-03-16 22:01:12 +1100 Graham Williams>
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

import 'package:konapod/models/vehicle.dart';
import 'package:konapod/theme/hyundai_theme.dart';
import 'package:konapod/widgets/primitives.dart';

class WarningsSection extends StatelessWidget {
  final Vehicle v;
  const WarningsSection({super.key, required this.v});
  @override
  Widget build(BuildContext context) {
    final warnings = <String>[
      if (v.isLowFuelWarning == true) 'Low fuel',
      if (v.tyrePressureWarningAll == true) 'Tyre pressure (all)',
      if (v.tyrePressureWarningFrontLeft == true) 'Tyre pressure FL',
      if (v.tyrePressureWarningFrontRight == true) 'Tyre pressure FR',
      if (v.tyrePressureWarningRearLeft == true) 'Tyre pressure RL',
      if (v.tyrePressureWarningRearRight == true) 'Tyre pressure RR',
      if (v.is12VBatteryWarning == true) '12V battery low',
      if (v.isSmartKeyBatteryWarning == true) 'Smart key battery',
      if (v.isWasherFluidWarning == true) 'Washer fluid low',
      if (v.isBrakingFluidWarning == true) 'Braking fluid low',
    ];
    return DashboardCard(
      child: warnings.isEmpty
          ? const Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: HyundaiColors.success,
                  size: 20,
                ),
                SizedBox(width: 10),
                Text(
                  'No active warnings',
                  style: TextStyle(
                    color: HyundaiColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: warnings
                  .map(
                    (w) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber,
                            color: HyundaiColors.error,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            w,
                            style: const TextStyle(
                              color: HyundaiColors.error,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}
