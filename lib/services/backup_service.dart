/// BackupService — export and restore all konapod Pod data as JSON.
///
/// A backup is a single JSON document containing the raw (decrypted) Turtle
/// content of every konapod data file on the Pod. Restoring writes each file
/// back, re-encrypting via solidpod. Because the raw Turtle is preserved
/// verbatim, the backup is format-agnostic and captures everything —
/// snapshots, latest, the index, the logbook and battery observations.
///
// Time-stamp: <2026-06-09>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3

library;

import 'dart:convert';

import 'package:konapod/services/pod_service.dart';

/// Result of a restore operation.
class RestoreResult {
  final int restored;
  final int failed;
  final String? error;
  const RestoreResult({this.restored = 0, this.failed = 0, this.error});

  bool get ok => error == null && failed == 0;
}

class BackupService {
  BackupService._();

  /// Current backup format version. Bump if the structure changes.
  static const int formatVersion = 1;

  /// Build a complete backup of all Pod data as a pretty-printed JSON string.
  ///
  /// Structure:
  /// {
  ///   "app": "konapod",
  ///   "formatVersion": 1,
  ///   "exportedAt": "<ISO8601>",
  ///   "files": { "<filename.ttl>": "<raw turtle>", ... }
  /// }
  static Future<String> exportAll() async {
    final filenames = await PodService.backupFilenames();
    final files = <String, String>{};

    for (final name in filenames) {
      final content = await PodService.readRawFile(name);
      // Skip files that don't exist or are empty — nothing to back up.
      if (content != null && content.isNotEmpty) {
        files[name] = content;
      }
    }

    final backup = <String, dynamic>{
      'app': 'konapod',
      'formatVersion': formatVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'files': files,
    };

    return const JsonEncoder.withIndent('  ').convert(backup);
  }

  /// Restore Pod data from a backup JSON [jsonStr]. Every file in the backup
  /// is written back to the Pod, overwriting existing content.
  ///
  /// Returns a [RestoreResult] summarising how many files were restored.
  static Future<RestoreResult> importAll(String jsonStr) async {
    Map<String, dynamic> backup;
    try {
      backup = jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      return RestoreResult(error: 'Not a valid JSON backup file.');
    }

    if (backup['app'] != 'konapod') {
      return const RestoreResult(
        error: 'This file is not a konapod backup.',
      );
    }

    final files = backup['files'];
    if (files is! Map) {
      return const RestoreResult(error: 'Backup contains no files.');
    }

    var restored = 0;
    var failed = 0;
    for (final entry in files.entries) {
      final name = entry.key.toString();
      final content = entry.value;
      if (content is! String) {
        failed++;
        continue;
      }
      try {
        await PodService.writeRawFile(name, content);
        restored++;
      } catch (_) {
        failed++;
      }
    }

    return RestoreResult(restored: restored, failed: failed);
  }
}
