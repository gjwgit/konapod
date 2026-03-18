/// HeroCard widget showing vehicle identity, status badges and range.
///
// Time-stamp: <Wednesday 2026-03-18 13:47:41 +1100 Graham Williams>
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
import 'package:intl/intl.dart';

import 'package:konapod/models/vehicle.dart';
import 'package:konapod/theme/hyundai_theme.dart';
import 'package:konapod/widgets/stat_card.dart';

class HeroCard extends StatelessWidget {
  final Vehicle v;
  const HeroCard({super.key, required this.v});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [HyundaiColors.primary, Color(0xFFB5714A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: HyundaiColors.primary.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      v.modelName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (v.color.isNotEmpty)
                      Text(
                        v.color,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: HyundaiColors.accent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  v.fuelType,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const Gap(16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusBadge(
                active: v.isLocked == true,
                activeLabel: 'Locked',
                inactiveLabel: 'Unlocked',
                activeColor: HyundaiColors.success,
              ),
              StatusBadge(
                active: v.isEngineRunning == true,
                activeLabel: 'Engine On',
                inactiveLabel: 'Engine Off',
                activeColor: HyundaiColors.warning,
              ),
//          if (v.isChargingOn == true)
              StatusBadge(
                active: v.isChargingOn == true,
                activeLabel: 'Charging',
                inactiveLabel: 'Not Charging',
                activeColor: HyundaiColors.accent,
              ),
//          if (v.isPluggedIn == true && v.isChargingOn != true)
              StatusBadge(
                active: v.isPluggedIn == true && v.isChargingOn != true,
                activeLabel: 'Plugged In',
                inactiveLabel: 'Not Plugged In',
                activeColor: const Color(0xFF6C63FF),
              ),
              if (v.isClimateOn == true)
                const StatusBadge(
                  active: true,
                  activeLabel: 'Climate On',
                  inactiveLabel: '',
                  activeColor: Color(0xFF00B4D8),
                ),
              if (v.isAccOn == true)
                const StatusBadge(
                  active: true,
                  activeLabel: 'ACC On',
                  inactiveLabel: '',
                  activeColor: HyundaiColors.warning,
                ),
            ],
          ),
          const Gap(14),
          Row(
            children: [
              if (v.evRangeKm != null || v.fuelRangeKm != null) ...[
                const Icon(Icons.route, color: Colors.white54, size: 16),
                const Gap(6),
                Text(
                  '${(v.evRangeKm ?? v.fuelRangeKm)!.round()} km current range',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
              if (v.batteryLevelPercent != null) ...[
                const Gap(16),
                const Icon(
                  Icons.battery_charging_full,
                  color: Colors.white54,
                  size: 16,
                ),
                const Gap(6),
                Text(
                  '${v.batteryLevelPercent!.round()}% charge',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
              const Gap(16),
              const Icon(Icons.speed, color: Colors.white54, size: 16),
              const Gap(6),
              Text(
                v.odometerKm != null
                    ? '${NumberFormat('#,##0').format(v.odometerKm!.round())} km total travelled'
                    : '– km',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              if (v.vin.isNotEmpty)
                Text(
                  v.vin.length > 8
                      ? '…${v.vin.substring(v.vin.length - 8)}'
                      : v.vin,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
