/// Model for a single day of driving stats parsed from the Bluelink API.
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
      double? d(String key) {
        final m = RegExp('$key=([0-9.e+-]+)').firstMatch(repr);
        return m != null ? double.tryParse(m.group(1)!) : null;
      }

      int? i(String key) {
        final m = RegExp('$key=([0-9]+)').firstMatch(repr);
        return m != null ? int.tryParse(m.group(1)!) : null;
      }

      // Parse date from datetime.datetime(yyyy, m, d, ...)
      final dm = RegExp(r'datetime\.datetime\((\d+),\s*(\d+),\s*(\d+)')
          .firstMatch(repr);
      if (dm == null) return null;
      final date = DateTime(
        int.parse(dm.group(1)!),
        int.parse(dm.group(2)!),
        int.parse(dm.group(3)!),
      );
      final dist = d('distance');
      if (dist == null) return null;
      return DailyDrivingStat(
        date: date,
        distanceKm: dist,
        totalConsumed: i('total_consumed'),
        engineConsumption: i('engine_consumption'),
        climateConsumption: i('climate_consumption'),
        electronicsConsumption: i('onboard_electronics_consumption'),
        regeneratedEnergy: i('regenerated_energy'),
        batteryCareConsumption: i('battery_care_consumption'),
      );
    } catch (_) {
      return null;
    }
  }

  /// Net efficiency for this day: (consumed - regen) / distance * 100, kWh/100km.
  double get netEfficiencyKwhPer100km {
    if (distanceKm == 0) return 0;
    final net = ((totalConsumed ?? 0) - (regeneratedEnergy ?? 0)) / 1000;
    return net / distanceKm * 100;
  }
}
