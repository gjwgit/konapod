/// Parses raw Bluelink API JSON into a Vehicle; provides mock data.
///
// Time-stamp: <Wednesday 2026-03-18 22:11:25 +1100 Graham Williams>
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

import 'package:konapod/models/vehicle.dart';

/// Parses a raw API JSON map into a [Vehicle].
/// Separated from [Vehicle] to keep the model class under the line limit.
Vehicle parseVehicleFromJson(Map<String, dynamic> j) {
  // NOTE: In Python bool is subclass of int.
  // The safe() function in bluelink_fetch.py now checks bool before int,
  // so booleans arrive as JSON true/false, not 1/0.
  bool? b(dynamic v) {
    if (v == null) return null;
    if (v is bool) return v;
    if (v is int) return v != 0;
    if (v is String) return v == 'true' || v == '1';
    return null;
  }

  double? d(dynamic v) {
    if (v == null) return null;
    if (v is bool) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  int? i(dynamic v) {
    if (v == null) return null;
    if (v is bool) return v ? 1 : 0;
    if (v is int) return v;
    if (v is double) return v.round();
    return int.tryParse(v.toString());
  }

  String fuelType = 'ICE';
  final raw = j['engine_type']?.toString().toUpperCase() ?? '';
  if (raw.contains('PHEV')) {
    fuelType = 'PHEV';
  } else if (raw.contains('EV')) {
    fuelType = 'EV';
  } else if (raw.contains('HEV')) {
    fuelType = 'HEV';
  }

  // Collect all remaining non-null fields as extras for the raw data view.
  const knownKeys = {
    'vehicleId',
    'id',
    'vin',
    'name',
    'model',
    'year',
    'engine_type',
    'color',
    'trim',
    'is_locked',
    'trunk_is_open',
    'hood_is_open',
    'front_left_door_is_open',
    'front_right_door_is_open',
    'back_left_door_is_open',
    'back_right_door_is_open',
    'engine_is_running',
    'acc_is_on',
    'air_control_is_on',
    'front_defrost_is_on',
    'back_window_heater_is_on',
    'steering_wheel_heater_is_on',
    'side_mirror_heater_is_on',
    'air_temperature',
    'front_left_seat_status',
    'front_right_seat_status',
    'rear_left_seat_status',
    'rear_right_seat_status',
    'fuel_level',
    'fuel_driving_range',
    'FuelSystem',
    'low_fuel_alert_is_on',
    'ev_battery_percentage',
    'ev_driving_range',
    'ev_battery_is_charging',
    'ev_battery_is_plugged_in',
    'ev_estimated_current_charge_duration',
    'ev_battery_capacity',
    'ev_target_range_charge_AC',
    'ev_target_range_charge_DC',
    'ev_charge_limits_ac',
    'ev_charge_limits_dc',
    'ev_charge_scheduled_on',
    'ev_12v_percentage',
    'AverageFuelEconomy',
    'data',
    'ev_battery_remain',
    'ev_battery_soh_percentage',
    'ev_charging_current',
    'ev_charging_power',
    'ev_estimated_fast_charge_duration',
    'ev_estimated_portable_charge_duration',
    'ev_estimated_station_charge_duration',
    'battery_12v_percentage',
    'battery_12v_warning_is_on',
    'odometer',
    'location_latitude',
    'location_longitude',
    'location_name',
    'tire_pressure_front_left_warning_is_on',
    'tire_pressure_front_right_warning_is_on',
    'tire_pressure_rear_left_warning_is_on',
    'tire_pressure_rear_right_warning_is_on',
    'tire_pressure_all_warning_is_on',
    'front_left_window_is_open',
    'front_right_window_is_open',
    'back_left_window_is_open',
    'back_right_window_is_open',
    'smart_key_battery_warning_is_on',
    'washer_fluid_warning_is_on',
    'brake_fluid_warning_is_on',
    'total_driving_range',
    'daily_driving_distance',
    'daily_stats',
    'total_power_consumed',
    'power_consumption_30d',
    'total_power_regenerated',
    'last_updated_at',
    'fetchedAt',
    'registration_date',
  };
  final extras = <String, dynamic>{};
  for (final entry in j.entries) {
    if (!knownKeys.contains(entry.key) &&
        entry.value != null &&
        entry.value != false &&
        entry.value != '' &&
        entry.value != 0) {
      extras[entry.key] = entry.value;
    }
  }

  return Vehicle(
    id: j['vehicleId']?.toString() ?? j['id']?.toString() ?? '',
    vin: j['vin']?.toString() ?? '',
    nickname: j['name']?.toString() ?? 'My Hyundai',
    modelName: j['model']?.toString() ?? '',
    modelYear: j['year']?.toString() ?? '',
    fuelType: fuelType,
    color: j['color']?.toString() ?? '',
    trim: j['trim']?.toString() ?? '',
    isLocked: b(j['is_locked']),
    isTrunkOpen: b(j['trunk_is_open']),
    isBonnetOpen: b(j['hood_is_open']),
    isDoorFrontLeftOpen: b(j['front_left_door_is_open']),
    isDoorFrontRightOpen: b(j['front_right_door_is_open']),
    isDoorRearLeftOpen: b(j['back_left_door_is_open']),
    isDoorRearRightOpen: b(j['back_right_door_is_open']),
    isEngineRunning: b(j['engine_is_running']),
    isAccOn: b(j['acc_is_on']),
    isClimateOn: b(j['air_control_is_on']),
    isDefrostingOn: b(j['front_defrost_is_on']),
    isRearWindowDefrostOn: b(j['back_window_heater_is_on']),
    isSteeringWheelHeatOn: b(j['steering_wheel_heater_is_on']),
    isSideMirrorHeatOn: b(j['side_mirror_heater_is_on']),
    targetTempC: d(j['air_temperature']),
    externalTempC: d(j['air_temperature']),
    seatHeatFrontLeft: i(j['front_left_seat_status']),
    seatHeatFrontRight: i(j['front_right_seat_status']),
    seatHeatRearLeft: i(j['rear_left_seat_status']),
    seatHeatRearRight: i(j['rear_right_seat_status']),
    seatCoolFrontLeft: i(j['front_left_seat_status']),
    seatCoolFrontRight: i(j['front_right_seat_status']),
    fuelLevelPercent: d(j['fuel_level']),
    fuelRangeKm: d(j['fuel_driving_range']),
    isLowFuelWarning: b(j['low_fuel_alert_is_on']),
    batteryLevelPercent: d(j['ev_battery_percentage']),
    evRangeKm: d(j['ev_driving_range']),
    isChargingOn: b(j['ev_battery_is_charging']),
    isPluggedIn: b(j['ev_battery_is_plugged_in']),
    estimatedChargeCompletionMinutes:
        d(j['ev_estimated_current_charge_duration']),
    batteryCapacityKwh: d(j['ev_battery_capacity']),
    batteryRemainKwh: d(j['ev_battery_remain']),
    batterySohPercent: d(j['ev_battery_soh_percentage']),
    chargingCurrentAc: d(j['ev_charging_current']),
    chargingPowerKw: d(j['ev_charging_power']),
    estimatedFastChargeMins: d(j['ev_estimated_fast_charge_duration']),
    estimatedPortableChargeMins: d(j['ev_estimated_portable_charge_duration']),
    estimatedStationChargeMins: d(j['ev_estimated_station_charge_duration']),
    targetSocAC: i(j['ev_charge_limits_ac']),
    targetSocDC: i(j['ev_charge_limits_dc']),
    isChargeScheduledOn: b(j['ev_charge_scheduled_on']),
    ev12vPercent: d(j['ev_12v_percentage']),
    efficiencyLatestTrip: d(
      (((j['data'] as Map?)?['Drivetrain'] as Map?)?['FuelSystem']
          as Map?)?['AverageFuelEconomy']?['Drive'],
    ),
    efficiencySinceCharging: d(
      (((j['data'] as Map?)?['Drivetrain'] as Map?)?['FuelSystem']
          as Map?)?['AverageFuelEconomy']?['AfterRefuel'],
    ),
    efficiencyOverall: d(
      (((j['data'] as Map?)?['Drivetrain'] as Map?)?['FuelSystem']
          as Map?)?['AverageFuelEconomy']?['Accumulated'],
    ),
    battery12VPercent: i(j['battery_12v_percentage']),
    is12VBatteryWarning: b(j['battery_12v_warning_is_on']),
    odometerKm: d(j['odometer']),
    latitude: d(j['location_latitude']),
    longitude: d(j['location_longitude']),
    locationAddress: j['location_name']?.toString(),
    tyrePressureWarningFrontLeft:
        b(j['tire_pressure_front_left_warning_is_on']),
    tyrePressureWarningFrontRight:
        b(j['tire_pressure_front_right_warning_is_on']),
    tyrePressureWarningRearLeft: b(j['tire_pressure_rear_left_warning_is_on']),
    tyrePressureWarningRearRight:
        b(j['tire_pressure_rear_right_warning_is_on']),
    tyrePressureWarningAll: b(j['tire_pressure_all_warning_is_on']),
    tyrePressureFrontLeft: d(
      (((j['data'] as Map?)?['Chassis'] as Map?)?['Axle'] as Map?)?['Row1']
          ?['Left']?['Tire']?['Pressure'],
    ),
    tyrePressureFrontRight: d(
      (((j['data'] as Map?)?['Chassis'] as Map?)?['Axle'] as Map?)?['Row1']
          ?['Right']?['Tire']?['Pressure'],
    ),
    tyrePressureRearLeft: d(
      (((j['data'] as Map?)?['Chassis'] as Map?)?['Axle'] as Map?)?['Row2']
          ?['Left']?['Tire']?['Pressure'],
    ),
    tyrePressureRearRight: d(
      (((j['data'] as Map?)?['Chassis'] as Map?)?['Axle'] as Map?)?['Row2']
          ?['Right']?['Tire']?['Pressure'],
    ),
    isWindowFrontLeftOpen: b(j['front_left_window_is_open']),
    isWindowFrontRightOpen: b(j['front_right_window_is_open']),
    isWindowRearLeftOpen: b(j['back_left_window_is_open']),
    isWindowRearRightOpen: b(j['back_right_window_is_open']),
    isSmartKeyBatteryWarning: b(j['smart_key_battery_warning_is_on']),
    isWasherFluidWarning: b(j['washer_fluid_warning_is_on']),
    isBrakingFluidWarning: b(j['brake_fluid_warning_is_on']),
    totalDrivenKm: d(j['total_driving_range']),
    dailyDrivenKm: d(j['daily_driving_distance']),
    dailyStats: (j['daily_stats'] as List? ?? [])
        .map((e) => DailyDrivingStat.fromRepr(e.toString()))
        .whereType<DailyDrivingStat>()
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date)),
    totalPowerConsumedKwh: i(j['total_power_consumed']),
    powerConsumption30dKwh: i(j['power_consumption_30d']),
    extras: extras,
    lastUpdated: j['last_updated_at'] != null
        ? DateTime.tryParse(j['last_updated_at'].toString())
        : null,
    fetchedAt: j['fetchedAt'] != null
        ? DateTime.tryParse(j['fetchedAt'].toString())
        : null,
    registrationDate: j['registration_date'] != null
        ? DateTime.tryParse(j['registration_date'].toString())
        : null,
  );
}

/// Returns a [Vehicle] populated with demo data for UI testing.
Vehicle mockVehicle() => const Vehicle(
      id: 'demo-001',
      vin: 'KMHL341ADNU012345',
      nickname: 'My KONA EV',
      modelName: 'KONA EV',
      modelYear: '2024',
      fuelType: 'EV',
      color: 'Cyber Grey',
      trim: 'Premium',
      isLocked: true,
      isTrunkOpen: false,
      isBonnetOpen: false,
      isDoorFrontLeftOpen: false,
      isDoorFrontRightOpen: false,
      isDoorRearLeftOpen: false,
      isDoorRearRightOpen: false,
      isEngineRunning: false,
      isAccOn: false,
      isClimateOn: false,
      isDefrostingOn: false,
      batteryLevelPercent: 78,
      evRangeKm: 328,
      isChargingOn: false,
      isPluggedIn: false,
      batteryCapacityKwh: 65.4,
      targetSocAC: 80,
      targetSocDC: 80,
      battery12VPercent: 85,
      odometerKm: 12348,
      latitude: -33.8688,
      longitude: 151.2093,
      tyrePressureWarningFrontLeft: false,
      tyrePressureWarningFrontRight: false,
      tyrePressureWarningRearLeft: false,
      tyrePressureWarningRearRight: false,
      lastUpdated: null,
    );
