/// HeroCard widget showing vehicle identity, status badges and range.
///
// Time-stamp: <Thursday 2026-03-19 09:06:02 +1100 Graham Williams>
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
import 'package:markdown_tooltip/markdown_tooltip.dart';

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
                      '${v.nickname} ${v.modelName} ${v.color} ${v.trim}',
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
              MarkdownTooltip(
                message: '**Locked / Unlocked**\n\n'
                    'Whether the car\'s central locking is engaged.\n\n'
                    'The Body Control Module reports this state. '
                    'See the *Doors* section below for individual door lock status.',
                child: StatusBadge(
                  active: v.isLocked == true,
                  activeLabel: 'Locked',
                  inactiveLabel: 'Unlocked',
                  activeColor: HyundaiColors.success,
                ),
              ),
              MarkdownTooltip(
                message: '**Engine / Motor**\n\n'
                    'Whether the drive motor is active and the car is in *Ready* mode.\n\n'
                    'On an EV this is equivalent to the ignition being on — '
                    'the car is ready to drive even though there is no combustion engine.',
                child: StatusBadge(
                  active: v.isEngineRunning == true,
                  activeLabel: 'Engine On',
                  inactiveLabel: 'Engine Off',
                  activeColor: HyundaiColors.warning,
                ),
              ),
              MarkdownTooltip(
                message: '**Accessory Mode**\n\n'
                    'The ignition is in the *accessory* position — electrical systems '
                    'such as the radio and climate fan are powered, but the motor '
                    'is not in Ready mode and the car cannot be driven.\n\n'
                    'On the Kona EV this occurs when you press the Start button '
                    'once without your foot on the brake.',
                child: StatusBadge(
                  active: v.isAccOn == true,
                  activeLabel: 'Accessory On',
                  inactiveLabel: 'Accessory Off',
                  activeColor: HyundaiColors.warning,
                ),
              ),
              MarkdownTooltip(
                message: '**Climate Control**\n\n'
                    'The heating or air conditioning system is currently running.\n\n'
                    'Climate can be active while the car is parked, for example '
                    'during a scheduled pre-conditioning session to warm or cool '
                    'the cabin before you get in — useful in summer and winter.',
                child: StatusBadge(
                  active: v.isClimateOn == true,
                  activeLabel: 'Climate On',
                  inactiveLabel: 'Climate Off',
                  activeColor: const Color(0xFF00B4D8),
                ),
              ),
              MarkdownTooltip(
                message: '**Plugged In**\n\n'
                    'The charging cable is physically connected to the car.\n\n'
                    'The car can be plugged in *without* actively charging — '
                    'for example if a scheduled charge is set for off-peak hours, '
                    'or the battery has already reached its target charge level.',
                child: StatusBadge(
                  active: v.isPluggedIn == true,
                  activeLabel: 'Plugged In',
                  inactiveLabel: 'Not Plugged In',
                  activeColor: HyundaiColors.accent,
                ),
              ),
              MarkdownTooltip(
                message: '**Charging**\n\n'
                    'The battery is actively receiving charge from the grid.\n\n'
                    'The car can be *Plugged In* but *Not Charging* if a charge '
                    'schedule is set, the battery is at its target level, '
                    'or charging has been paused by the car or charger.',
                child: StatusBadge(
                  active: v.isChargingOn == true,
                  activeLabel: 'Charging',
                  inactiveLabel: 'Not Charging',
                  activeColor: HyundaiColors.accent,
                ),
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
