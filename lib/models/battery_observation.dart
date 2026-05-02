/// BatteryObservation — a single battery % vs range reading.
///
// Time-stamp: <Thursday 2026-05-01 09:00:00 +1000 Graham Williams>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3

library;

/// One recorded data point linking battery state-of-charge to EV range.

class BatteryObservation {
  final DateTime timestamp;
  final double batteryPct; // 0–100
  final double rangeKm;
  final double? odometerKm;
  final double? remainKwh;

  const BatteryObservation({
    required this.timestamp,
    required this.batteryPct,
    required this.rangeKm,
    this.odometerKm,
    this.remainKwh,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'batteryPct': batteryPct,
        'rangeKm': rangeKm,
        if (odometerKm != null) 'odometerKm': odometerKm,
        if (remainKwh != null) 'remainKwh': remainKwh,
      };

  factory BatteryObservation.fromJson(Map<String, dynamic> j) =>
      BatteryObservation(
        timestamp: DateTime.parse(j['timestamp'] as String),
        batteryPct: (j['batteryPct'] as num).toDouble(),
        rangeKm: (j['rangeKm'] as num).toDouble(),
        odometerKm: (j['odometerKm'] as num?)?.toDouble(),
        remainKwh: (j['remainKwh'] as num?)?.toDouble(),
      );

  @override
  String toString() => 'BatteryObservation(${timestamp.toIso8601String()}, '
      '${batteryPct.toStringAsFixed(1)}%, ${rangeKm.toStringAsFixed(0)} km'
      '${odometerKm != null ? ', ${odometerKm!.toStringAsFixed(0)} km odo' : ''}'
      '${remainKwh != null ? ', ${remainKwh!.toStringAsFixed(1)} kWh' : ''})';
}
