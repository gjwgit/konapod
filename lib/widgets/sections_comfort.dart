/// Comfort section widgets: climate, tyre, seat heat, vehicle info.
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

import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import 'package:konapod/models/vehicle.dart';
import 'package:konapod/theme/hyundai_theme.dart';
import 'package:konapod/widgets/kv_table.dart';
import 'package:konapod/widgets/primitives.dart';
import 'package:konapod/widgets/tyre_tile.dart';

class ClimateSection extends StatelessWidget {
  final Vehicle v;
  const ClimateSection({super.key, required this.v});
  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusRow(
            Icons.air,
            'Climate Control',
            v.isClimateOn == true,
            const Color(0xFF00B4D8),
          ),
          StatusRow(
            Icons.ac_unit,
            'Front Defrost',
            v.isDefrostingOn == true,
            HyundaiColors.accent,
          ),
          StatusRow(
            Icons.back_hand_outlined,
            'Rear Window Heat',
            v.isRearWindowDefrostOn == true,
            HyundaiColors.accent,
          ),
          StatusRow(
            Icons.settings_input_component,
            'Steering Wheel Heat',
            v.isSteeringWheelHeatOn == true,
            HyundaiColors.warning,
          ),
          StatusRow(
            Icons.wb_sunny_outlined,
            'Side Mirror Heat',
            v.isSideMirrorHeatOn == true,
            HyundaiColors.warning,
          ),
          if (v.targetTempC != null) ...[
            Divider(
              height: 16,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            KVRow('Set Temperature', '${v.targetTempC!.toStringAsFixed(1)}°C'),
          ],
          if (v.seatHeatFrontLeft != null ||
              v.seatHeatFrontRight != null ||
              v.seatHeatRearLeft != null ||
              v.seatHeatRearRight != null) ...[
            Divider(
              height: 16,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            Row(
              children: [
                Icon(
                  Icons.airline_seat_recline_normal,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 16,
                ),
                const Gap(8),
                Expanded(
                  child: Text(
                    'Seat Heat',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (v.seatHeatFrontLeft != null)
                  SeatBadge('FL', v.seatHeatFrontLeft!),
                if (v.seatHeatFrontRight != null) ...[
                  const Gap(4),
                  SeatBadge('FR', v.seatHeatFrontRight!),
                ],
                if (v.seatHeatRearLeft != null) ...[
                  const Gap(4),
                  SeatBadge('RL', v.seatHeatRearLeft!),
                ],
                if (v.seatHeatRearRight != null) ...[
                  const Gap(4),
                  SeatBadge('RR', v.seatHeatRearRight!),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class TyreSection extends StatelessWidget {
  final Vehicle v;
  const TyreSection({super.key, required this.v});

  String _pressure(double? kpa) {
    if (kpa == null || kpa == 255) return '–';
    return '${kpa.round()} kPa';
  }

  @override
  Widget build(BuildContext context) {
    final allOk = v.tyrePressureWarningAll != true &&
        v.tyrePressureWarningFrontLeft != true &&
        v.tyrePressureWarningFrontRight != true &&
        v.tyrePressureWarningRearLeft != true &&
        v.tyrePressureWarningRearRight != true;
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.tire_repair,
                color: allOk ? HyundaiColors.success : HyundaiColors.error,
                size: 18,
              ),
              const Gap(8),
              Text(
                allOk ? 'All tyres OK' : 'Tyre pressure warning',
                style: TextStyle(
                  color: allOk ? HyundaiColors.success : HyundaiColors.error,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const Gap(12),
          Row(
            children: [
              Expanded(
                child: TyreTile(
                  'Front Left',
                  v.tyrePressureWarningFrontLeft,
                  pressure: _pressure(v.tyrePressureFrontLeft),
                ),
              ),
              const Gap(8),
              Expanded(
                child: TyreTile(
                  'Front Right',
                  v.tyrePressureWarningFrontRight,
                  pressure: _pressure(v.tyrePressureFrontRight),
                ),
              ),
            ],
          ),
          const Gap(8),
          Row(
            children: [
              Expanded(
                child: TyreTile(
                  'Rear Left',
                  v.tyrePressureWarningRearLeft,
                  pressure: _pressure(v.tyrePressureRearLeft),
                ),
              ),
              const Gap(8),
              Expanded(
                child: TyreTile(
                  'Rear Right',
                  v.tyrePressureWarningRearRight,
                  pressure: _pressure(v.tyrePressureRearRight),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class InfoSection extends StatelessWidget {
  final Vehicle v;
  const InfoSection({super.key, required this.v});
  @override
  Widget build(BuildContext context) {
    final rows = <MapEntry<String, String>>[
      if (v.vin.isNotEmpty) MapEntry('VIN', v.vin),
      MapEntry('Model', v.modelName),
      if (v.modelYear.isNotEmpty) MapEntry('Year', v.modelYear),
      if (v.trim.isNotEmpty) MapEntry('Trim', v.trim),
      MapEntry('Powertrain', v.fuelType),
      if (v.color.isNotEmpty) MapEntry('Colour', v.color),
      if (v.odometerKm != null)
        MapEntry(
          'Odometer',
          '${NumberFormat('#,##0').format(v.odometerKm!.round())} km',
        ),
      if (v.totalDrivenKm != null)
        MapEntry(
          'Total Driven',
          '${NumberFormat('#,##0').format(v.totalDrivenKm!.round())} km',
        ),
      if (v.dailyDrivenKm != null)
        MapEntry('Today', '${v.dailyDrivenKm!.toStringAsFixed(1)} km'),
      if (v.latitude != null && v.longitude != null)
        MapEntry(
          'GPS',
          '${v.latitude!.toStringAsFixed(5)}, ${v.longitude!.toStringAsFixed(5)}',
        ),
      if (v.locationAddress != null && v.locationAddress!.isNotEmpty)
        MapEntry('Address', v.locationAddress!),
      if (v.battery12VPercent != null)
        MapEntry('12V Battery', '${v.battery12VPercent}%'),
    ];
    return KVTable(rows);
  }
}

class ExtrasSection extends StatelessWidget {
  final Map<String, dynamic> extras;
  const ExtrasSection({super.key, required this.extras});
  @override
  Widget build(BuildContext context) {
    final rows = extras.entries
        .where(
          (e) =>
              e.value != null &&
              e.value != false &&
              e.value != 0 &&
              e.value != '',
        )
        .map((e) => MapEntry(e.key.replaceAll('_', ' '), e.value.toString()))
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return KVTable(rows);
  }
}
