import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

import '../models/vehicle.dart';

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

  String _findScript() {
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
    for (final cmd in ['python3', 'python']) {
      try {
        final r = await Process.run(cmd, ['--version']);
        if (r.exitCode == 0) return cmd;
      } catch (_) {}
    }
    throw BluelinkApiException(
      'Python 3 not found.\nRun: sudo apt install python3 python3-pip',
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
    final script = _findScript();

    if (!File(script).existsSync()) {
      throw BluelinkApiException(
        'bluelink_fetch.py not found.\nExpected at: $script',
      );
    }

    final check =
        await Process.run(python, ['-c', 'import hyundai_kia_connect_api']);
    if (check.exitCode != 0) {
      throw BluelinkApiException(
        'Python library not installed.\nRun: pip install hyundai-kia-connect-api',
      );
    }

    dev.log('[Bluelink] Running Python script…', name: 'BluelinkService');

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
    dev.log('[Bluelink] exit=${result.exitCode}', name: 'BluelinkService');
    if (stderr.isNotEmpty)
      dev.log('[Bluelink] stderr=$stderr', name: 'BluelinkService');

    if (stdout.isEmpty) {
      throw BluelinkApiException(
          'No output from Python script.\nstderr: $stderr');
    }

    Map<String, dynamic> data;
    try {
      data = jsonDecode(stdout) as Map<String, dynamic>;
    } catch (_) {
      throw BluelinkApiException(
        'Could not parse output:\n${stdout.substring(0, stdout.length.clamp(0, 300))}',
      );
    }

    if (data.containsKey('error')) {
      throw BluelinkApiException(
        '${data['error']}${data['fix'] != null ? '\n\nFix: ${data['fix']}' : ''}',
      );
    }

    final rawList =
        (data['vehicles'] as List? ?? []).cast<Map<String, dynamic>>();
    if (rawList.isEmpty)
      throw BluelinkApiException('No vehicles found on this account.');

    final fetchedAt = DateTime.now().toIso8601String();
    final vehicles = <Vehicle>[];
    for (final raw in rawList) {
      try {
        vehicles.add(Vehicle.fromApiJson({...raw, 'fetchedAt': fetchedAt}));
      } catch (e, st) {
        dev.log('[Bluelink] Parse error: $e\n$st', name: 'BluelinkService');
        throw BluelinkApiException(
            'Failed to parse vehicle data: $e\n\nRaw: $raw');
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
