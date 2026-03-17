/// DoorsSection widget showing lock, engine, charging and door states.
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
import 'package:konapod/widgets/tiles.dart';

class DoorsSection extends StatelessWidget {
  final Vehicle v;
  const DoorsSection({super.key, required this.v});
  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: BigStatusTile(
                  icon: v.isLocked == true ? Icons.lock : Icons.lock_open,
                  label: 'Doors',
                  value: v.isLocked == null
                      ? '–'
                      : v.isLocked!
                          ? 'Locked'
                          : 'Unlocked',
                  color: v.isLocked == true
                      ? HyundaiColors.success
                      : HyundaiColors.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: BigStatusTile(
                  icon: Icons.directions_car,
                  label: 'Engine',
                  value: v.isEngineRunning == null
                      ? '–'
                      : v.isEngineRunning!
                          ? 'Running'
                          : 'Off',
                  color: v.isEngineRunning == true
                      ? HyundaiColors.warning
                      : HyundaiColors.success,
                ),
              ),
            ],
          ),
          if (v.isEV) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: BigStatusTile(
                    icon: Icons.power,
                    label: 'Charging',
                    value: v.isChargingOn == null
                        ? '–'
                        : v.isChargingOn!
                            ? 'Charging'
                            : 'Not charging',
                    color: v.isChargingOn == true
                        ? HyundaiColors.accent
                        : HyundaiColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: BigStatusTile(
                    icon: Icons.electrical_services,
                    label: 'Plug',
                    value: v.isPluggedIn == null
                        ? '–'
                        : v.isPluggedIn!
                            ? 'Plugged in'
                            : 'Unplugged',
                    color: v.isPluggedIn == true
                        ? const Color(0xFF6C63FF)
                        : HyundaiColors.success,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: DoorTile('Front Left', v.isDoorFrontLeftOpen)),
              const SizedBox(width: 8),
              Expanded(child: DoorTile('Front Right', v.isDoorFrontRightOpen)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: DoorTile('Rear Left', v.isDoorRearLeftOpen)),
              const SizedBox(width: 8),
              Expanded(child: DoorTile('Rear Right', v.isDoorRearRightOpen)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: DoorTile('Boot', v.isTrunkOpen)),
              const SizedBox(width: 8),
              Expanded(child: DoorTile('Bonnet', v.isBonnetOpen)),
            ],
          ),
        ],
      ),
    );
  }
}
