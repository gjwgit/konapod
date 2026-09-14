/// Fill a log entry's end readings from a fresh Bluelink snapshot.
///
// Time-stamp: <Sunday 2026-09-14 10:00:00 +1000 Graham Williams>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://opensource.org/license/gpl-3-0

library;

import 'package:flutter/widgets.dart';

import 'package:konapod/pages/log_charge_section.dart';
import 'package:konapod/services/app_provider.dart';

/// Refresh from Bluelink and populate the end readings of a log entry with
/// the current vehicle state, along with the charge duration, energy and
/// cost those readings imply.
///
/// [isMounted] reports whether the editor is still on screen: the refresh is
/// a network round trip, and writing to controllers the editor has disposed
/// would throw.

Future<void> fetchEndReadings({
  required AppProvider provider,
  required bool Function() isMounted,
  required DateTime startTimestamp,
  required TextEditingController odoCtrl,
  required TextEditingController battCtrl,
  required TextEditingController remainCtrl,
  required TextEditingController rangeCtrl,
  required TextEditingController startRemainCtrl,
  required LogChargeSectionState? charge,
}) async {
  await provider.refresh();
  if (!isMounted()) return;
  final v = provider.selectedVehicle;
  if (v == null) return;
  odoCtrl.text = v.odometerKm != null ? v.odometerKm!.round().toString() : '';
  final endBatt = v.batteryLevelPercent;
  battCtrl.text = endBatt != null ? endBatt.toStringAsFixed(0) : '';
  remainCtrl.text = v.batteryRemainKwh != null
      ? (v.batteryRemainKwh! / 3600).toStringAsFixed(1)
      : '';
  rangeCtrl.text = v.evRangeKm != null ? v.evRangeKm!.toStringAsFixed(0) : '';

  // ── Derived charge values ──────────────────────────────────────────────

  // 20260726 gjw Duration: from entry timestamp to the charge end time.
  // The API has no charge-session history, but the car reports state to
  // the server when charging stops, so when not charging the snapshot's
  // lastUpdated is typically the charge-stop time — more accurate than now.
  // Fall back to now while still charging or if lastUpdated is missing.

  final now = DateTime.now();
  var end = now;
  final reported = v.lastUpdated;
  if (v.isChargingOn != true &&
      reported != null &&
      reported.isAfter(startTimestamp) &&
      reported.isBefore(now)) {
    end = reported;
  }
  final durationMin = end.difference(startTimestamp).inMinutes.clamp(0, 9999);

  // Energy delivered: end remaining kWh − start remaining kWh.
  // Use the directly measured remaining values — more accurate than
  // deriving from battery percentage × capacity.

  final startRemain = double.tryParse(startRemainCtrl.text.trim());
  final endRemain =
      v.batteryRemainKwh != null ? v.batteryRemainKwh! / 3600 : null;
  double? energyKwh;
  double? totalCost;
  if (endRemain != null && startRemain != null) {
    final delta = endRemain - startRemain;
    if (delta > 0) {
      energyKwh = delta;

      // Total cost: energy × cost per kWh if available.

      final costPerKwh = charge?.costPerKwh;
      if (costPerKwh != null && costPerKwh > 0) {
        totalCost = energyKwh * costPerKwh;
      }
    }
  }

  charge?.populateFromBluelink(
    durationMinutes: durationMin,
    energyKwh: energyKwh,
    totalCost: totalCost,
  );
}
