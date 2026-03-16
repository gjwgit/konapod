/// Full vehicle data model — populated from hyundai_kia_connect_api Python library.
/// Parsed entry from the daily_stats list returned by the Bluelink API.
/// Each entry is stored as a Python repr string like:
///   DailyDrivingStats(date=datetime.datetime(2026, 3, 14, 0, 0),
///     total_consumed=4479, ..., distance=15.7, distance_unit='km')
class DailyDrivingStat {
  final DateTime date;
  final double distanceKm;
  final int? totalConsumed;
  final int? engineConsumption;
  final int? climateConsumption;
  final int? electronicsConsumption;
  final int? regeneratedEnergy;
  final int? batteryCareConsumption;

  const DailyDrivingStat({
    required this.date,
    required this.distanceKm,
    this.totalConsumed,
    this.engineConsumption,
    this.climateConsumption,
    this.electronicsConsumption,
    this.regeneratedEnergy,
    this.batteryCareConsumption,
  });

  /// Parses a Python repr string like:
  ///   DailyDrivingStats(date=datetime.datetime(2026, 3, 14, 0, 0), ..., distance=15.7, ...)
  static DailyDrivingStat? fromRepr(String repr) {
    try {
      double? _d(String key) {
        final m = RegExp('$key=([0-9.e+-]+)').firstMatch(repr);
        return m != null ? double.tryParse(m.group(1)!) : null;
      }
      int? _i(String key) {
        final m = RegExp('$key=([0-9]+)').firstMatch(repr);
        return m != null ? int.tryParse(m.group(1)!) : null;
      }
      // Parse date from datetime.datetime(yyyy, m, d, ...)
      final dm = RegExp(r'datetime\.datetime\((\d+),\s*(\d+),\s*(\d+)').firstMatch(repr);
      if (dm == null) return null;
      final date = DateTime(
        int.parse(dm.group(1)!),
        int.parse(dm.group(2)!),
        int.parse(dm.group(3)!),
      );
      final dist = _d('distance');
      if (dist == null) return null;
      return DailyDrivingStat(
        date: date,
        distanceKm: dist,
        totalConsumed: _i('total_consumed'),
        engineConsumption: _i('engine_consumption'),
        climateConsumption: _i('climate_consumption'),
        electronicsConsumption: _i('onboard_electronics_consumption'),
        regeneratedEnergy: _i('regenerated_energy'),
        batteryCareConsumption: _i('battery_care_consumption'),
      );
    } catch (_) {
      return null;
    }
  }
}

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
  final int? targetSocAC;
  final int? targetSocDC;
  final bool? isChargeScheduledOn;
  final double? ev12vPercent;

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

  // ── Raw extras (everything else non-null from API) ───────────────────────
  final Map<String, dynamic> extras;

  // ── Timestamps ───────────────────────────────────────────────────────────
  final DateTime? lastUpdated;

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
    this.targetSocAC,
    this.targetSocDC,
    this.isChargeScheduledOn,
    this.ev12vPercent,
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
    this.extras = const {},
    this.lastUpdated,
  });

  bool get isEV  => fuelType == 'EV'  || fuelType == 'PHEV';
  bool get isICE => fuelType == 'ICE' || fuelType == 'HEV' || fuelType == 'PHEV';

  factory Vehicle.fromApiJson(Map<String, dynamic> j) {
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

    // Collect all remaining non-null fields as extras for the raw data view
    const knownKeys = {
      'vehicleId','id','vin','name','model','year','engine_type','color','trim',
      'is_locked','trunk_is_open','hood_is_open',
      'front_left_door_is_open','front_right_door_is_open',
      'back_left_door_is_open','back_right_door_is_open',
      'engine_is_running','acc_is_on',
      'air_control_is_on','front_defrost_is_on','back_window_heater_is_on',
      'steering_wheel_heater_is_on','side_mirror_heater_is_on','air_temperature',
      'front_left_seat_status','front_right_seat_status',
      'rear_left_seat_status','rear_right_seat_status',
      'fuel_level','fuel_driving_range','low_fuel_alert_is_on',
      'ev_battery_percentage','ev_driving_range',
      'ev_battery_is_charging','ev_battery_is_plugged_in',
      'ev_estimated_current_charge_duration','ev_battery_capacity',
      'ev_target_range_charge_AC','ev_target_range_charge_DC',
      'ev_charge_limits_ac','ev_charge_limits_dc',
      'ev_charge_scheduled_on','ev_12v_percentage',
      'battery_12v_percentage','battery_12v_warning_is_on',
      'odometer','location_latitude','location_longitude','location_name',
      'tire_pressure_front_left_warning_is_on','tire_pressure_front_right_warning_is_on',
      'tire_pressure_rear_left_warning_is_on','tire_pressure_rear_right_warning_is_on',
      'tire_pressure_all_warning_is_on',
      'front_left_window_is_open','front_right_window_is_open',
      'back_left_window_is_open','back_right_window_is_open',
      'smart_key_battery_warning_is_on','washer_fluid_warning_is_on',
      'brake_fluid_warning_is_on',
      'total_driving_range','daily_driving_distance','daily_stats',
      'last_updated_at',
    };
    final extras = <String, dynamic>{};
    for (final entry in j.entries) {
      if (!knownKeys.contains(entry.key) && entry.value != null &&
          entry.value != false && entry.value != '' && entry.value != 0) {
        extras[entry.key] = entry.value;
      }
    }

    return Vehicle(
      id:        j['vehicleId']?.toString() ?? j['id']?.toString() ?? '',
      vin:       j['vin']?.toString() ?? '',
      nickname:  j['name']?.toString() ?? 'My Hyundai',
      modelName: j['model']?.toString() ?? '',
      modelYear: j['year']?.toString() ?? '',
      fuelType:  fuelType,
      color:     j['color']?.toString() ?? '',
      trim:      j['trim']?.toString() ?? '',

      isLocked:             b(j['is_locked']),
      isTrunkOpen:          b(j['trunk_is_open']),
      isBonnetOpen:         b(j['hood_is_open']),
      isDoorFrontLeftOpen:  b(j['front_left_door_is_open']),
      isDoorFrontRightOpen: b(j['front_right_door_is_open']),
      isDoorRearLeftOpen:   b(j['back_left_door_is_open']),
      isDoorRearRightOpen:  b(j['back_right_door_is_open']),

      isEngineRunning: b(j['engine_is_running']),
      isAccOn:         b(j['acc_is_on']),

      isClimateOn:           b(j['air_control_is_on']),
      isDefrostingOn:        b(j['front_defrost_is_on']),
      isRearWindowDefrostOn: b(j['back_window_heater_is_on']),
      isSteeringWheelHeatOn: b(j['steering_wheel_heater_is_on']),
      isSideMirrorHeatOn:    b(j['side_mirror_heater_is_on']),
      targetTempC:           d(j['air_temperature']),
      externalTempC:         d(j['air_temperature']),

      seatHeatFrontLeft:  i(j['front_left_seat_status']),
      seatHeatFrontRight: i(j['front_right_seat_status']),
      seatHeatRearLeft:   i(j['rear_left_seat_status']),
      seatHeatRearRight:  i(j['rear_right_seat_status']),
      seatCoolFrontLeft:  i(j['front_left_seat_status']),
      seatCoolFrontRight: i(j['front_right_seat_status']),

      fuelLevelPercent: d(j['fuel_level']),
      fuelRangeKm:      d(j['fuel_driving_range']),
      isLowFuelWarning: b(j['low_fuel_alert_is_on']),

      batteryLevelPercent:              d(j['ev_battery_percentage']),
      evRangeKm:                        d(j['ev_driving_range']),
      isChargingOn:                     b(j['ev_battery_is_charging']),
      isPluggedIn:                      b(j['ev_battery_is_plugged_in']),
      estimatedChargeCompletionMinutes: d(j['ev_estimated_current_charge_duration']),
      batteryCapacityKwh:               d(j['ev_battery_capacity']),
      targetSocAC:                      i(j['ev_target_range_charge_AC'] ?? j['ev_charge_limits_ac']),
      targetSocDC:                      i(j['ev_target_range_charge_DC'] ?? j['ev_charge_limits_dc']),
      isChargeScheduledOn:              b(j['ev_charge_scheduled_on']),
      ev12vPercent:                     d(j['ev_12v_percentage']),

      battery12VPercent:   i(j['battery_12v_percentage']),
      is12VBatteryWarning: b(j['battery_12v_warning_is_on']),

      odometerKm:      d(j['odometer']),
      latitude:        d(j['location_latitude']),
      longitude:       d(j['location_longitude']),
      locationAddress: j['location_name']?.toString(),

      tyrePressureWarningFrontLeft:  b(j['tire_pressure_front_left_warning_is_on']),
      tyrePressureWarningFrontRight: b(j['tire_pressure_front_right_warning_is_on']),
      tyrePressureWarningRearLeft:   b(j['tire_pressure_rear_left_warning_is_on']),
      tyrePressureWarningRearRight:  b(j['tire_pressure_rear_right_warning_is_on']),
      tyrePressureWarningAll:        b(j['tire_pressure_all_warning_is_on']),

      isWindowFrontLeftOpen:  b(j['front_left_window_is_open']),
      isWindowFrontRightOpen: b(j['front_right_window_is_open']),
      isWindowRearLeftOpen:   b(j['back_left_window_is_open']),
      isWindowRearRightOpen:  b(j['back_right_window_is_open']),

      isSmartKeyBatteryWarning: b(j['smart_key_battery_warning_is_on']),
      isWasherFluidWarning:     b(j['washer_fluid_warning_is_on']),
      isBrakingFluidWarning:    b(j['brake_fluid_warning_is_on']),

      totalDrivenKm: d(j['total_driving_range']),
      dailyDrivenKm: d(j['daily_driving_distance']),
      dailyStats: (j['daily_stats'] as List? ?? [])
          .map((e) => DailyDrivingStat.fromRepr(e.toString()))
          .whereType<DailyDrivingStat>()
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date)),

      extras: extras,

      lastUpdated: j['last_updated_at'] != null
          ? DateTime.tryParse(j['last_updated_at'].toString())
          : null,
    );
  }

  factory Vehicle.mock() => Vehicle(
    id: 'demo-001', vin: 'KMHL341ADNU012345',
    nickname: 'My KONA EV', modelName: 'KONA EV', modelYear: '2024',
    fuelType: 'EV', color: 'Cyber Grey', trim: 'Premium',
    isLocked: true, isTrunkOpen: false, isBonnetOpen: false,
    isDoorFrontLeftOpen: false, isDoorFrontRightOpen: false,
    isDoorRearLeftOpen: false, isDoorRearRightOpen: false,
    isEngineRunning: false, isAccOn: false,
    isClimateOn: false, isDefrostingOn: false,
    batteryLevelPercent: 78, evRangeKm: 328,
    isChargingOn: false, isPluggedIn: false,
    batteryCapacityKwh: 65.4, targetSocAC: 80, targetSocDC: 80,
    battery12VPercent: 85, odometerKm: 12348,
    latitude: -33.8688, longitude: 151.2093,
    tyrePressureWarningFrontLeft: false, tyrePressureWarningFrontRight: false,
    tyrePressureWarningRearLeft: false, tyrePressureWarningRearRight: false,
    lastUpdated: null,
  );
}
