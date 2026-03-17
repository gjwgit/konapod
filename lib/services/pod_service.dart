/// Solid Pod service: read, write and delete TTL-wrapped vehicle snapshots.
///
// Time-stamp: <Tuesday 2026-03-17 19:53:36 +1100 Graham Williams>
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

import 'dart:convert';
import 'dart:developer' as dev;

import 'package:solidpod/solidpod.dart';

import 'package:konapod/utils/pod_utils.dart';

/// Service for reading and writing vehicle status to a Solid Pod.
///
/// All files are stored as valid Turtle (.ttl) documents with the
/// JSON payload embedded as a string literal, then encrypted by
/// solidpod using the user's security key.
///
/// File layout (all relative to the app directory set in SolidLogin):
///   status_YYYYMMDDTHHMMSS.ttl  -- individual snapshots
///   latest.ttl                  -- copy of the most recent snapshot
///   index.ttl                   -- list of all snapshot filenames

class PodService {
  // Turtle namespace prefixes used in every file we write.
  static const _prefixes = '@prefix konapod: <https://'
      'konapod.solidcommunity.au/ont/> .\n'
      '@prefix xsd:     <http://'
      'www.w3.org/2001/XMLSchema#> .\n';

  /// Wraps a JSON string in a Turtle document as a plain string literal.
  /// The predicate is a konapod: term so the file is self-describing.
  static String _jsonToTtl(String predicate, String json) {
    // Triple-quote sequences inside the JSON must be escaped.
    final safe = json.replaceAll('"""', r'\"\"\"');
    return '$_prefixes\n<> konapod:$predicate """$safe""" .\n';
  }

  /// Extracts the first triple-quoted literal from a Turtle document.
  static String? _ttlToLiteral(String ttl) {
    final first = ttl.indexOf('"""');
    final last = ttl.lastIndexOf('"""');
    if (first == -1 || last == first) return null;
    return ttl.substring(first + 3, last).replaceAll(r'\"\"\"', '"""');
  }

  // ── Public API ────────────────────────────────────────────────────────

  /// Saves a status snapshot and updates latest.ttl + index.ttl.
  /// Returns null on success, or an error message on failure.
  static Future<String?> saveStatusWithIndex(
    Map<String, dynamic> data,
  ) async {
    try {
      final filename = makeStatusFilename();
      final json = const JsonEncoder.withIndent('  ').convert(data);
      final ttl = _jsonToTtl('vehicleStatus', json);

      dev.log('[Pod] Writing $filename...', name: 'PodService');
      await writePod(filename, ttl);
      dev.log('[Pod] Saved $filename', name: 'PodService');

      await writePod('latest.ttl', ttl, overwrite: true);
      dev.log('[Pod] Updated latest.ttl', name: 'PodService');

      final index = await _readIndex();
      if (!index.contains(filename)) {
        index.add(filename);
        index.sort((a, b) => b.compareTo(a));
      }
      await _writeIndex(index);
      dev.log('[Pod] Updated index.ttl', name: 'PodService');

      return null;
    } catch (e, st) {
      dev.log('[Pod] Save error: $e\n$st', name: 'PodService');
      return e.toString();
    }
  }

  /// Loads the latest status snapshot from the pod.
  static Future<Map<String, dynamic>?> loadLatestStatus() async {
    try {
      final index = await _readIndex();
      if (index.isNotEmpty) return loadStatusFile(index.first);
    } catch (_) {}
    try {
      final ttl = await readPod('latest.ttl');
      if (ttl.isNotEmpty) return _parseTtlSnapshot(ttl);
    } catch (_) {}
    return null;
  }

  /// Loads a specific snapshot by filename.
  static Future<Map<String, dynamic>?> loadStatusFile(
    String filename,
  ) async {
    try {
      final ttl = await readPod(filename);
      if (ttl.isNotEmpty) return _parseTtlSnapshot(ttl);
    } catch (e) {
      dev.log('[Pod] Load error ($filename): $e', name: 'PodService');
    }
    return null;
  }

  /// Returns all snapshot filenames from index.ttl, newest first.
  static Future<List<String>> listStatusFiles() async {
    try {
      return await _readIndex();
    } catch (e) {
      dev.log('[Pod] List error: $e', name: 'PodService');
      return [];
    }
  }

  /// Permanently deletes a snapshot file from the pod and removes it
  /// from index.ttl. Returns null on success, error string on failure.
  static Future<String?> deleteStatusFile(String filename) async {
    try {
      await deleteFile(fileUrl: await getFileUrl('konapod/data/$filename'));
      dev.log('[Pod] Deleted $filename', name: 'PodService');

      final index = await _readIndex();
      index.remove(filename);
      await _writeIndex(index);
      dev.log('[Pod] Removed $filename from index.ttl', name: 'PodService');

      return null;
    } catch (e, st) {
      dev.log('[Pod] Delete error: $e\n$st', name: 'PodService');
      return e.toString();
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────

  static Map<String, dynamic>? _parseTtlSnapshot(String ttl) {
    final json = _ttlToLiteral(ttl);
    if (json == null) return null;
    try {
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<List<String>> _readIndex() async {
    try {
      final ttl = await readPod('index.ttl');
      if (ttl.isEmpty) return [];
      final literal = _ttlToLiteral(ttl);
      if (literal == null) return [];
      final list = List<String>.from(jsonDecode(literal) as List? ?? []);
      return list..sort((a, b) => b.compareTo(a));
    } catch (_) {
      return [];
    }
  }

  static Future<void> _writeIndex(List<String> index) async {
    final ttl = _jsonToTtl('snapshotIndex', jsonEncode(index));
    await writePod('index.ttl', ttl, overwrite: true);
  }
}
