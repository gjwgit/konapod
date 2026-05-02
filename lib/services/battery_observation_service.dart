/// Service for persisting battery % vs range observations to a Solid Pod.
///
// Time-stamp: <Thursday 2026-05-01 09:00:00 +1000 Graham Williams>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3

library;

import 'dart:convert';
import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';

import 'package:solidpod/solidpod.dart';

import 'package:konapod/models/battery_observation.dart';

/// Manages a single append-only JSON file in the Pod that stores every
/// battery % / range / odometer observation collected from the car.
///
/// File: `battery_observations.ttl`
///
/// The JSON payload is a list of observation objects, newest last.

class BatteryObservationService {
  static const _file = 'battery_observations.ttl';
  static const _prefixes = '@prefix konapod: <https://'
      'konapod.solidcommunity.au/ont/> .\n'
      '@prefix xsd:     <http://'
      'www.w3.org/2001/XMLSchema#> .\n';

  static String _toTtl(String json) {
    final safe = json.replaceAll('"""', r'\"\"\"');
    return '$_prefixes\n<> konapod:batteryObservations """$safe""" .\n';
  }

  static String? _extractJson(String ttl) {
    final re = RegExp(
      r'konapod:batteryObservations\s+"""(.*?)"""\s*\.',
      dotAll: true,
    );
    final m = re.firstMatch(ttl);
    return m?.group(1)?.replaceAll(r'\"\"\"', '"""');
  }

  // ── Load ──────────────────────────────────────────────────────────────────

  static List<BatteryObservation> _deduplicate(List<BatteryObservation> obs) {
    // Group by (batteryPct, rangeKm) — same reading from multiple snapshots.
    // Within each group keep the entry with the most fields populated.
    final groups = <String, List<BatteryObservation>>{};
    for (final o in obs) {
      final key =
          '${o.batteryPct.toStringAsFixed(1)}_${o.rangeKm.toStringAsFixed(0)}';
      groups.putIfAbsent(key, () => []).add(o);
    }
    return groups.values.map((group) {
      // Score: +1 for each non-null optional field. Keep highest score;
      // on tie keep the most recent timestamp.
      group.sort((a, b) {
        final sa =
            (a.remainKwh != null ? 1 : 0) + (a.odometerKm != null ? 1 : 0);
        final sb =
            (b.remainKwh != null ? 1 : 0) + (b.odometerKm != null ? 1 : 0);
        if (sb != sa) return sb - sa; // higher score first
        return b.timestamp.compareTo(a.timestamp); // newer first
      });
      return group.first;
    }).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  static Future<List<BatteryObservation>> load() async {
    try {
      final ttl = await readPod(_file);
      if (ttl.isEmpty) return [];
      final jsonStr = _extractJson(ttl);
      if (jsonStr == null) return [];
      final raw = jsonDecode(jsonStr) as List<dynamic>;
      final obs = raw
          .map((e) => BatteryObservation.fromJson(e as Map<String, dynamic>))
          .toList();
      // Apply deduplication and migration.
      var result = obs;

      // Migrate: values > 1000 were stored in raw Wh·s — divide by 3600.
      final needsMigration =
          result.any((o) => o.remainKwh != null && o.remainKwh! > 1000);
      if (needsMigration) {
        result = result.map((o) {
          if (o.remainKwh != null && o.remainKwh! > 1000) {
            return BatteryObservation(
              timestamp: o.timestamp,
              batteryPct: o.batteryPct,
              rangeKm: o.rangeKm,
              odometerKm: o.odometerKm,
              remainKwh: o.remainKwh! / 3600,
            );
          }
          return o;
        }).toList();
      }

      // Deduplicate: same % + range → keep most complete row.
      final deduped = _deduplicate(result);
      final changed = needsMigration || deduped.length < result.length;
      if (changed) saveAll(deduped); // fire-and-forget resave
      return deduped;
    } catch (e) {
      dev.log('[BatteryObs] load error: $e', name: 'BatteryObsService');
      return [];
    }
  }

  // ── Append one observation ────────────────────────────────────────────────

  /// Records [obs] only if it differs meaningfully from the last saved point
  /// (battery % changed by ≥ 1 or range changed by ≥ 5 km).
  /// Returns null on success or an error string.

  static Future<String?> record(BatteryObservation obs) async {
    try {
      final existing = await load();

      // Deduplicate: skip if this reading is essentially the same as the last.
      if (existing.isNotEmpty) {
        final last = existing.last;
        final pctDelta = (obs.batteryPct - last.batteryPct).abs();
        final rangeDelta = (obs.rangeKm - last.rangeKm).abs();
        if (pctDelta < 1.0 && rangeDelta < 5.0) {
          dev.log(
            '[BatteryObs] skipping duplicate (Δ% ${pctDelta.toStringAsFixed(1)}, '
            'Δkm ${rangeDelta.toStringAsFixed(0)})',
            name: 'BatteryObsService',
          );
          return null; // not an error, just not worth recording
        }
      }

      existing.add(obs);
      final json = const JsonEncoder.withIndent('  ')
          .convert(existing.map((o) => o.toJson()).toList());
      final ttl = _toTtl(json);

      final error = await _write(ttl);
      if (error != null) return error;

      dev.log('[BatteryObs] recorded: $obs', name: 'BatteryObsService');
      return null;
    } catch (e, st) {
      debugPrint('[BatteryObs] record error: $e\n$st');
      return e.toString();
    }
  }

  static Future<String?> _write(String ttl) async {
    try {
      await writePod(_file, ttl);
      return null;
    } catch (_) {
      // File doesn't exist yet or overwrite needed.
      try {
        await writePod(_file, ttl, overwrite: true);
        return null;
      } catch (e) {
        return e.toString();
      }
    }
  }

  // ── Full replace (for clear/import) ──────────────────────────────────────

  static Future<String?> saveAll(List<BatteryObservation> observations) async {
    final json = const JsonEncoder.withIndent('  ')
        .convert(observations.map((o) => o.toJson()).toList());
    return _write(_toTtl(json));
  }
}
