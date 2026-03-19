/// Vehicle data model: all fields, constructor, computed getters.
///
// Time-stamp: <Monday 2026-03-17 00:00:00 +1100 Graham Williams>
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

import 'package:konapod/models/daily_driving_stat.dart';
import 'package:konapod/models/vehicle_parser.dart';

export 'daily_driving_stat.dart';
export 'vehicle_parser.dart';

/// Full vehicle data model — populated from hyundai_kia_connect_api Python library.
class Vehicle {
  // ── Identity ──────────────────────────────────────────────────────────────
  final String id;
  final String vin;
  final String nickname;
  final String modelName;
  final String modelYear;
  final String fuelType;
  final String color;
  final String trim;

  // ── Lock / doors ─────────────────────────────────────────────────────────
  final bool? isLocked;
  final bool? isTrunkOpen;
  final bool? isBonnetOpen;
  final bool? isDoorFrontLeftOpen;
  final bool? isDoorFrontRightOpen;
  final bool? isDoorRearLeftOpen;
  final bool? isDoorRearRightOpen;

  // ── Engine / ignition ────────────────────────────────────────────────────
  final bool? isEngineRunning;
  final bool? isAccOn;

  // ── Climate ──────────────────────────────────────────────────────────────
  final bool? isClimateOn;
  final bool? isDefrostingOn;
  final bool? isRearWindowDefrostOn;
  final bool? isSteeringWheelHeatOn;
  final bool? isSideMirrorHeatOn;
  final double? targetTempC;
  final double? externalTempC;

  // ── Seat heating/cooling ─────────────────────────────────────────────────
  final int? seatHeatFrontLeft;
  final int? seatHeatFrontRight;
  final int? seatHeatRearLeft;
  final int? seatHeatRearRight;
  final int? seatCoolFrontLeft;
  final int? seatCoolFrontRight;

  // ── Fuel / range ─────────────────────────────────────────────────────────
  final double? fuelLevelPercent;
  final double? fuelRangeKm;
  final bool? isLowFuelWarning;

  // ── EV / battery ─────────────────────────────────────────────────────────
  final double? batteryLevelPercent;
  final double? evRangeKm;
  final bool? isChargingOn;
  final bool? isPluggedIn;
  final double? estimatedChargeCompletionMinutes;
  final double? batteryCapacityKwh;
  final double? batteryRemainKwh;
  final double? batterySohPercent;
  final double? chargingCurrentAc;
  final double? chargingPowerKw;
  final double? estimatedFastChargeMins;
  final double? estimatedPortableChargeMins;
  final double? estimatedStationChargeMins;
  final int? targetSocAC;
  final int? targetSocDC;
  final bool? isChargeScheduledOn;
  final double? ev12vPercent;

  // ── EV efficiency (kWh/100km) ─────────────────────────────────────────────
  /// Latest trip efficiency in kWh/100km.
  final double? efficiencyLatestTrip;

  /// Since last charge efficiency in kWh/100km.
  final double? efficiencySinceCharging;

  /// Overall accumulated efficiency in kWh/100km.
  final double? efficiencyOverall;

  // ── 12V battery ──────────────────────────────────────────────────────────
  final int? battery12VPercent;
  final bool? is12VBatteryWarning;

  // ── Odometer / location ──────────────────────────────────────────────────
  final double? odometerKm;
  final double? latitude;
  final double? longitude;
  final String? locationAddress;

  // ── Tyre pressure ────────────────────────────────────────────────────────
  final bool? tyrePressureWarningFrontLeft;
  final bool? tyrePressureWarningFrontRight;
  final bool? tyrePressureWarningRearLeft;
  final bool? tyrePressureWarningRearRight;
  final bool? tyrePressureWarningAll;

  /// Actual tyre pressures in kPa (from data.Chassis.Axle).
  final double? tyrePressureFrontLeft;
  final double? tyrePressureFrontRight;
  final double? tyrePressureRearLeft;
  final double? tyrePressureRearRight;

  // ── Windows ──────────────────────────────────────────────────────────────
  final bool? isWindowFrontLeftOpen;
  final bool? isWindowFrontRightOpen;
  final bool? isWindowRearLeftOpen;
  final bool? isWindowRearRightOpen;

  // ── Safety / warnings ────────────────────────────────────────────────────
  final bool? isSmartKeyBatteryWarning;
  final bool? isWasherFluidWarning;
  final bool? isBrakingFluidWarning;

  // ── Driving stats ─────────────────────────────────────────────────────────
  final double? totalDrivenKm;
  final double? dailyDrivenKm;
  final List<DailyDrivingStat> dailyStats;

  /// Lifetime total power consumed, in Wh (from API field total_power_consumed).
  final int? totalPowerConsumedKwh;

  /// Power consumed in the last 30 days, in Wh (from API field power_consumption_30d).
  final int? powerConsumption30dKwh;

  // ── Raw extras (everything else non-null from API) ───────────────────────
  final Map<String, dynamic> extras;

  // ── Timestamps ───────────────────────────────────────────────────────────
  final DateTime? lastUpdated;
  final DateTime? fetchedAt;
  final DateTime? registrationDate;

  const Vehicle({
    required this.id,
    required this.vin,
    required this.nickname,
    required this.modelName,
    required this.modelYear,
    required this.fuelType,
    required this.color,
    this.trim = '',
    this.isLocked,
    this.isTrunkOpen,
    this.isBonnetOpen,
    this.isDoorFrontLeftOpen,
    this.isDoorFrontRightOpen,
    this.isDoorRearLeftOpen,
    this.isDoorRearRightOpen,
    this.isEngineRunning,
    this.isAccOn,
    this.isClimateOn,
    this.isDefrostingOn,
    this.isRearWindowDefrostOn,
    this.isSteeringWheelHeatOn,
    this.isSideMirrorHeatOn,
    this.targetTempC,
    this.externalTempC,
    this.seatHeatFrontLeft,
    this.seatHeatFrontRight,
    this.seatHeatRearLeft,
    this.seatHeatRearRight,
    this.seatCoolFrontLeft,
    this.seatCoolFrontRight,
    this.fuelLevelPercent,
    this.fuelRangeKm,
    this.isLowFuelWarning,
    this.batteryLevelPercent,
    this.evRangeKm,
    this.isChargingOn,
    this.isPluggedIn,
    this.estimatedChargeCompletionMinutes,
    this.batteryCapacityKwh,
    this.batteryRemainKwh,
    this.batterySohPercent,
    this.chargingCurrentAc,
    this.chargingPowerKw,
    this.estimatedFastChargeMins,
    this.estimatedPortableChargeMins,
    this.estimatedStationChargeMins,
    this.targetSocAC,
    this.targetSocDC,
    this.isChargeScheduledOn,
    this.ev12vPercent,
    this.efficiencyLatestTrip,
    this.efficiencySinceCharging,
    this.efficiencyOverall,
    this.battery12VPercent,
    this.is12VBatteryWarning,
    this.odometerKm,
    this.latitude,
    this.longitude,
    this.locationAddress,
    this.tyrePressureWarningFrontLeft,
    this.tyrePressureWarningFrontRight,
    this.tyrePressureWarningRearLeft,
    this.tyrePressureWarningRearRight,
    this.tyrePressureWarningAll,
    this.tyrePressureFrontLeft,
    this.tyrePressureFrontRight,
    this.tyrePressureRearLeft,
    this.tyrePressureRearRight,
    this.isWindowFrontLeftOpen,
    this.isWindowFrontRightOpen,
    this.isWindowRearLeftOpen,
    this.isWindowRearRightOpen,
    this.isSmartKeyBatteryWarning,
    this.isWasherFluidWarning,
    this.isBrakingFluidWarning,
    this.totalDrivenKm,
    this.dailyDrivenKm,
    this.dailyStats = const [],
    this.totalPowerConsumedKwh,
    this.powerConsumption30dKwh,
    this.extras = const {},
    this.lastUpdated,
    this.fetchedAt,
    this.registrationDate,
  });

  bool get isEV => fuelType == 'EV' || fuelType == 'PHEV';
  bool get isICE =>
      fuelType == 'ICE' || fuelType == 'HEV' || fuelType == 'PHEV';

  // ── Computed stats from dailyStats ───────────────────────────────────────
  /// Total distance across all daily stats entries, in km.
  double get statsTotalDistanceKm =>
      dailyStats.fold(0.0, (s, d) => s + d.distanceKm);

  /// Total energy consumed across all daily stats entries, in kWh.
  double get statsTotalConsumedKwh =>
      dailyStats.fold(0.0, (s, d) => s + (d.totalConsumed ?? 0)) / 1000;

  /// Total energy regenerated across all daily stats entries, in kWh.
  double get statsTotalRegenKwh =>
      dailyStats.fold(0.0, (s, d) => s + (d.regeneratedEnergy ?? 0)) / 1000;

  /// Net consumption (consumed − regen) across all daily stats entries, in kWh.
  double get statsNetConsumedKwh => statsTotalConsumedKwh - statsTotalRegenKwh;

  /// Average net efficiency across all daily stats entries, in kWh/100km.
  double? get statsAvgEfficiency {
    final km = statsTotalDistanceKm;
    if (km == 0) return null;
    return statsNetConsumedKwh / km * 100;
  }

  /// Best (lowest net kWh/100km) daily stat.
  DailyDrivingStat? get statsBestDay {
    final days = dailyStats.where((d) => d.distanceKm > 0).toList();
    if (days.isEmpty) return null;
    return days.reduce(
      (a, b) => a.netEfficiencyKwhPer100km < b.netEfficiencyKwhPer100km ? a : b,
    );
  }

  /// Worst (highest net kWh/100km) daily stat.
  DailyDrivingStat? get statsWorstDay {
    final days = dailyStats.where((d) => d.distanceKm > 0).toList();
    if (days.isEmpty) return null;
    return days.reduce(
      (a, b) => a.netEfficiencyKwhPer100km > b.netEfficiencyKwhPer100km ? a : b,
    );
  }

  factory Vehicle.fromApiJson(Map<String, dynamic> j) =>
      parseVehicleFromJson(j);

  factory Vehicle.mock() => mockVehicle();
}
