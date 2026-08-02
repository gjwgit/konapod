/// Bluelink service: spawns Python subprocess to fetch live vehicle data.
///
// Time-stamp: <Friday 2026-03-27 18:50:07 +1100 Graham Williams>
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
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:konapod/models/vehicle.dart';

/// Bluelink service — Linux/desktop only.
/// Spawns bluelink_fetch.py as a subprocess using hyundai_kia_connect_api.
/// Requires: pip install hyundai-kia-connect-api

class BluelinkApiException implements Exception {
  final String message;
  BluelinkApiException(this.message);
  @override
  String toString() => message;
}

class BluelinkService {
  bool _authenticated = false;
  String? _username, _password, _pin;
  List<Vehicle>? _cachedVehicles;

  bool get isAuthenticated => _authenticated;

  String findScript() {
    final candidates = [
      '${File(Platform.resolvedExecutable).parent.path}/bluelink_fetch.py',
      '${Directory.current.path}/bluelink_fetch.py',
      '${Directory.current.parent.path}/bluelink_fetch.py',
    ];
    for (final path in candidates) {
      if (File(path).existsSync()) return path;
    }
    return candidates[1];
  }

  Future<String> _findPython() async {
    // Ordered preference:
    //  1. A venv created specifically for konapod at a predictable location.
    //  2. The system python3 / python (library installed with
    //     pip install hyundai-kia-connect-api --break-system-packages).
    final home = Platform.environment['HOME'] ?? '';
    final venvCandidates = [
      '$home/.local/share/konapod/venv/bin/python',
      '$home/.konapod-venv/bin/python',
      '${File(Platform.resolvedExecutable).parent.path}/venv/bin/python',
    ];
    final systemCandidates = ['python3', 'python'];

    for (final cmd in [...venvCandidates, ...systemCandidates]) {
      try {
        final r = await Process.run(cmd, ['--version']);
        if (r.exitCode == 0) {
          debugPrint('[Bluelink] Using Python: $cmd');
          return cmd;
        }
      } catch (_) {
        // Not found at this path — try next.
      }
    }
    throw BluelinkApiException(
      'Python 3 not found.\n\n'
      'Option A (simplest):\n'
      '  pip install hyundai-kia-connect-api --break-system-packages\n\n'
      'Option B (venv):\n'
      '  python3 -m venv ~/.local/share/konapod/venv\n'
      '  ~/.local/share/konapod/venv/bin/pip install hyundai-kia-connect-api',
    );
  }

  Future<void> login({
    required String username,
    required String password,
    required String pin,
  }) async {
    _username = username;
    _password = password;
    _pin = pin;
    _cachedVehicles = await _fetchFromPython();
    _authenticated = true;
  }

  Future<List<Vehicle>> getVehicles() async {
    if (_cachedVehicles != null) return _cachedVehicles!;
    return _fetchFromPython();
  }

  Future<void> refresh() async {
    _cachedVehicles = await _fetchFromPython();
  }

  Future<List<Vehicle>> _fetchFromPython() async {
    final python = await _findPython();
    final script = findScript();

    if (!File(script).existsSync()) {
      throw BluelinkApiException(
        'bluelink_fetch.py not found.\nExpected at: $script',
      );
    }

    final check =
        await Process.run(python, ['-c', 'import hyundai_kia_connect_api']);
    debugPrint('IMPORT $python hyundai_kia_connect_api');
    if (check.exitCode != 0) {
      throw BluelinkApiException(
        'Python library not installed.\nRun: pip install hyundai-kia-connect-api',
      );
    }

    dev.log('[Bluelink] Running Python script…', name: 'BluelinkService');
    // 20260803 gjw Log the interpreter and script actually used — a stale
    // script copy or a venv with an outdated hyundai_kia_connect_api has
    // caused wrong timestamps before, and this pins it down immediately.
    dev.log(
      '[Bluelink] python=$python script=$script',
      name: 'BluelinkService',
    );

    final result = await Process.run(
      python,
      [script, _username!, _password!, _pin!],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    ).timeout(
      const Duration(seconds: 90),
      onTimeout: () => throw BluelinkApiException('Timed out after 90s.'),
    );

    final stdout = (result.stdout as String).trim();
    final stderr = (result.stderr as String).trim();
    debugPrint('STDERR $stderr');
    dev.log('[Bluelink] exit=${result.exitCode}', name: 'BluelinkService');
    if (stderr.isNotEmpty) {
      dev.log('[Bluelink] stderr=$stderr', name: 'BluelinkService');
    }

    if (stdout.isEmpty) {
      throw BluelinkApiException(
        'The login helper exited without output '
        '(exit code ${result.exitCode}).'
        '${stderr.isNotEmpty ? '\n\n$stderr' : ''}'
        '\n\nIf this persists, log out and back in on the official Hyundai '
        'Bluelink / Kia Connect app, then try again.',
      );
    }

    Map<String, dynamic> data;
    try {
      data = jsonDecode(stdout) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[Bluelink] JSON parse error: $e');
      throw BluelinkApiException(
        'Could not parse output:\n${stdout.substring(0, stdout.length.clamp(0, 300))}',
      );
    }

    if (data.containsKey('error')) {
      final error = '${data['error']}';
      final fix = data['fix'];

      // The Bluelink/Kia Connect server commonly rejects a login that works
      // fine in the official app, especially after repeated API attempts —
      // logging out and back in via the official app re-establishes a valid
      // session. Surface that hint for authentication failures.
      final isAuthFailure = error.toLowerCase().contains('login') ||
          error.toLowerCase().contains('auth');

      final buffer = StringBuffer(error);
      if (fix != null) {
        buffer.write('\n\nFix: $fix');
      }
      if (isAuthFailure) {
        buffer.write(
          '\n\nIf your credentials are correct but login keeps failing, '
          'log out and back in on the official Hyundai Bluelink / Kia Connect '
          'app, then try again. Repeated attempts can temporarily lock the '
          'account until the official app re-establishes a session.',
        );
      }

      // Log the Python traceback (not shown in the user dialog) to aid future
      // debugging without overwhelming the user.
      if (data['traceback'] != null) {
        dev.log(
          '[Bluelink] script traceback:\n${data['traceback']}',
          name: 'BluelinkService',
        );
      }

      throw BluelinkApiException(buffer.toString());
    }

    final rawList =
        (data['vehicles'] as List? ?? []).cast<Map<String, dynamic>>();
    if (rawList.isEmpty) {
      throw BluelinkApiException('No vehicles found on this account.');
    }

    final fetchedAt = DateTime.now().toIso8601String();
    final vehicles = <Vehicle>[];
    for (final raw in rawList) {
      try {
        vehicles.add(Vehicle.fromApiJson({...raw, 'fetchedAt': fetchedAt}));
      } catch (e, st) {
        debugPrint('[Bluelink] Vehicle parse error: $e\n$st');
        dev.log('[Bluelink] Parse error: $e\n$st', name: 'BluelinkService');
        throw BluelinkApiException(
          'Failed to parse vehicle data: $e\n\nRaw: $raw',
        );
      }
    }
    _rawJson = {
      'vehicles': rawList,
      'fetchedAt': fetchedAt,
    };
    return vehicles;
  }

  /// Returns the raw JSON map from the last Python fetch (for pod saving).
  /// Caches the raw output from the Python script on each fetch.
  Map<String, dynamic>? _rawJson;

  Future<Map<String, dynamic>> getRawVehicleJson() async {
    if (_rawJson != null) return _rawJson!;
    // Re-fetch if not cached
    await _fetchFromPython();
    return _rawJson ??
        {'vehicles': [], 'fetchedAt': DateTime.now().toIso8601String()};
  }

  void logout() {
    _authenticated = false;
    _cachedVehicles = null;
    _rawJson = null;
    _username = null;
    _password = null;
    _pin = null;
  }
}
