/// LogEntry — a single log book entry for the vehicle.
///
// Time-stamp: <Friday 2026-03-27 18:00:00 +1100 Graham Williams>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://opensource.org/license/gpl-3-0

library;

/// A single entry in the vehicle log book.
///
/// Captures a point-in-time note with vehicle state at time of writing.

class LogEntry {
  final String id;
  final DateTime timestamp;
  final String title;
  final String note;

  // ── Vehicle state at time of entry ────────────────────────────────────────

  final double? odometerKm;
  final double? batteryLevelPercent;
  final double? evRangeKm;
  final double? batteryRemainKwh;
  final double? latitude;
  final double? longitude;
  final String? locationAddress;

  const LogEntry({
    required this.id,
    required this.timestamp,
    required this.title,
    this.note = '',
    this.odometerKm,
    this.batteryLevelPercent,
    this.evRangeKm,
    this.batteryRemainKwh,
    this.latitude,
    this.longitude,
    this.locationAddress,
  });

  // ── Serialisation ─────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'title': title,
        'note': note,
        if (odometerKm != null) 'odometerKm': odometerKm,
        if (batteryLevelPercent != null)
          'batteryLevelPercent': batteryLevelPercent,
        if (evRangeKm != null) 'evRangeKm': evRangeKm,
        if (batteryRemainKwh != null) 'batteryRemainKwh': batteryRemainKwh,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (locationAddress != null) 'locationAddress': locationAddress,
      };

  factory LogEntry.fromJson(Map<String, dynamic> j) => LogEntry(
        id: j['id'] as String,
        timestamp: DateTime.parse(j['timestamp'] as String),
        title: j['title'] as String,
        note: j['note'] as String? ?? '',
        odometerKm: (j['odometerKm'] as num?)?.toDouble(),
        batteryLevelPercent: (j['batteryLevelPercent'] as num?)?.toDouble(),
        evRangeKm: (j['evRangeKm'] as num?)?.toDouble(),
        batteryRemainKwh: (j['batteryRemainKwh'] as num?)?.toDouble(),
        latitude: (j['latitude'] as num?)?.toDouble(),
        longitude: (j['longitude'] as num?)?.toDouble(),
        locationAddress: j['locationAddress'] as String?,
      );

  LogEntry copyWith({
    String? id,
    DateTime? timestamp,
    String? title,
    String? note,
    Object? odometerKm = _sentinel,
    Object? batteryLevelPercent = _sentinel,
    Object? evRangeKm = _sentinel,
    Object? batteryRemainKwh = _sentinel,
    Object? latitude = _sentinel,
    Object? longitude = _sentinel,
    Object? locationAddress = _sentinel,
  }) =>
      LogEntry(
        id: id ?? this.id,
        timestamp: timestamp ?? this.timestamp,
        title: title ?? this.title,
        note: note ?? this.note,
        odometerKm:
            odometerKm == _sentinel ? this.odometerKm : odometerKm as double?,
        batteryLevelPercent: batteryLevelPercent == _sentinel
            ? this.batteryLevelPercent
            : batteryLevelPercent as double?,
        evRangeKm:
            evRangeKm == _sentinel ? this.evRangeKm : evRangeKm as double?,
        batteryRemainKwh: batteryRemainKwh == _sentinel
            ? this.batteryRemainKwh
            : batteryRemainKwh as double?,
        latitude: latitude == _sentinel ? this.latitude : latitude as double?,
        longitude:
            longitude == _sentinel ? this.longitude : longitude as double?,
        locationAddress: locationAddress == _sentinel
            ? this.locationAddress
            : locationAddress as String?,
      );
}

const _sentinel = Object();
