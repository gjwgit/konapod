/// Central ChangeNotifier: manages vehicle state, data source and actions.
///
// Time-stamp: <Wednesday 2026-03-18 08:32:28 +1100 Graham Williams>
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

import 'package:flutter/foundation.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:konapod/models/log_entry.dart';
import 'package:konapod/models/vehicle.dart';
import 'package:konapod/services/bluelink_service.dart';
import 'package:konapod/services/pod_service.dart';

enum AppState { idle, loading, loaded, error }

enum DataSource { bluelink, pod, none }

// Secure storage instance — shared across the app.
const _storage = FlutterSecureStorage();

class AppProvider extends ChangeNotifier {
  final BluelinkService _api = BluelinkService();

  AppState _state = AppState.idle;
  String? _errorMessage;
  List<Vehicle> _vehicles = [];
  List<LogEntry> _logEntries = [];
  int _selectedVehicleIndex = 0;
  bool _isRefreshing = false;
  bool _logLoading = false;
  DataSource _dataSource = DataSource.none;
  String? _loadedFilename; // which pod file is currently loaded

  AppState get state => _state;
  String? get errorMessage => _errorMessage;
  List<Vehicle> get vehicles => _vehicles;
  Vehicle? get selectedVehicle =>
      _vehicles.isNotEmpty ? _vehicles[_selectedVehicleIndex] : null;
  bool get isAuthenticated => _api.isAuthenticated;
  bool get isRefreshing => _isRefreshing;
  bool get logLoading => _logLoading;
  DataSource get dataSource => _dataSource;
  String? get loadedFilename => _loadedFilename;
  bool get hasData => _vehicles.isNotEmpty;
  List<LogEntry> get logEntries {
    final sorted = [..._logEntries];
    sorted.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return List.unmodifiable(sorted);
  }

  // ── Auto-login (desktop/bluelink) ────────────────────────────────────────

  Future<bool> tryAutoLogin() async {
    final username = await _storage.read(key: 'bl_username');
    final password = await _storage.read(key: 'bl_password');
    final pin = await _storage.read(key: 'bl_pin');
    if (username != null && password != null && pin != null) {
      return login(username: username, password: password, pin: pin);
    }
    return false;
  }

  Future<bool> login({
    required String username,
    required String password,
    required String pin,
  }) async {
    _state = AppState.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      await _api.login(username: username, password: password, pin: pin);
      await _storage.write(key: 'bl_username', value: username);
      await _storage.write(key: 'bl_password', value: password);
      await _storage.write(key: 'bl_pin', value: pin);
      _vehicles = await _api.getVehicles();
      _selectedVehicleIndex = 0;
      _dataSource = DataSource.bluelink;
      _loadedFilename = null;
      _state = AppState.loaded;
      notifyListeners();
      return true;
    } on BluelinkApiException catch (e) {
      debugPrint('[AppProvider] BluelinkApiException: ${e.message}');
      _state = AppState.error;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e, st) {
      debugPrint('[AppProvider] Unexpected error: $e\n$st');
      _state = AppState.error;
      _errorMessage = 'Error: ${e.runtimeType}\n$e';
      notifyListeners();
      return false;
    }
  }

  // ── Pod data loading ─────────────────────────────────────────────────────

  Future<bool> loadFromPod() async {
    _state = AppState.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      // Load vehicle status and log entries independently — log entries
      // should be available even if no vehicle snapshot exists yet.
      final data = await PodService.loadLatestStatus();
      await loadLogFromPod();

      if (data == null) {
        _state = AppState.error;
        _errorMessage = 'No status data found on your Solid Pod.\n'
            'Log in to Bluelink and save a snapshot first.\n'
            'Provide credentials under Settings for Bluelink.\n'
            'Alternatively ensure you have cached your Security Key.';
        notifyListeners();
        return false;
      }
      return _loadVehicleFromMap(data, source: DataSource.pod);
    } catch (e, st) {
      debugPrint('[AppProvider] loadFromPod error: $e\n$st');
      _state = AppState.error;
      _errorMessage = 'Pod load error: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> loadPodFile(String filename) async {
    _state = AppState.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final data = await PodService.loadStatusFile(filename);
      if (data == null) {
        _state = AppState.error;
        _errorMessage = 'Could not load $filename from pod.';
        notifyListeners();
        return false;
      }
      _loadedFilename = filename;
      return _loadVehicleFromMap(data, source: DataSource.pod);
    } catch (e, st) {
      debugPrint('[AppProvider] loadPodFile error: $e\n$st');
      _state = AppState.error;
      _errorMessage = 'Pod load error: $e';
      notifyListeners();
      return false;
    }
  }

  bool _loadVehicleFromMap(
    Map<String, dynamic> data, {
    required DataSource source,
  }) {
    // data may be a single vehicle dict or {vehicles: [...]}
    List<Map<String, dynamic>> rawList;
    if (data.containsKey('vehicles')) {
      rawList = (data['vehicles'] as List).cast<Map<String, dynamic>>();
    } else {
      rawList = [data];
    }
    if (rawList.isEmpty) {
      _state = AppState.error;
      _errorMessage = 'No vehicle data in file.';
      notifyListeners();
      return false;
    }
    _vehicles = rawList.map((r) => Vehicle.fromApiJson(r)).toList();
    _selectedVehicleIndex = 0;
    _dataSource = source;
    _state = AppState.loaded;
    notifyListeners();
    return true;
  }

  // ── Export ───────────────────────────────────────────────────────────────

  /// Returns the raw vehicle data map for JSON export.
  /// Uses cached data from the last Bluelink fetch if available,
  /// otherwise serialises from the loaded vehicle model.
  Future<Map<String, dynamic>?> getRawJsonForExport() async {
    if (_vehicles.isEmpty) return null;
    if (_dataSource == DataSource.bluelink) {
      try {
        return await _api.getRawVehicleJson();
      } catch (_) {}
    }
    // Fall back: rebuild a map from the parsed Vehicle model
    final v = selectedVehicle;
    if (v == null) return null;
    return {
      'vehicleId': v.id,
      'vin': v.vin,
      'name': v.nickname,
      'model': v.modelName,
      'year': v.modelYear,
      'engine_type': v.fuelType,
      'color': v.color,
      'is_locked': v.isLocked,
      'odometer': v.odometerKm,
      'ev_battery_percentage': v.batteryLevelPercent,
      'ev_driving_range': v.evRangeKm,
      'ev_battery_is_charging': v.isChargingOn,
      'ev_battery_is_plugged_in': v.isPluggedIn,
      'daily_driving_distance': v.dailyDrivenKm,
      'total_driving_range': v.totalDrivenKm,
      'last_updated_at': v.lastUpdated?.toIso8601String(),
      'exportedAt': DateTime.now().toIso8601String(),
      ...v.extras,
    };
  }

  // ── Save to pod ──────────────────────────────────────────────────────────

  Future<bool> saveToPod() async {
    if (_vehicles.isEmpty) return false;
    try {
      final rawJson = await _api.getRawVehicleJson();
      final error = await PodService.saveStatusWithIndex(rawJson);
      if (error != null) {
        _errorMessage = error;
        notifyListeners();
        return false;
      }
      return true;
    } catch (e, st) {
      debugPrint('[AppProvider] saveToPod error: $e\n$st');
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── Refresh ──────────────────────────────────────────────────────────────

  Future<void> refresh() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    _errorMessage = null;
    notifyListeners();
    try {
      if (_dataSource == DataSource.bluelink && isAuthenticated) {
        await _api.refresh();
        _vehicles = await _api.getVehicles();
        _state = AppState.loaded;
      } else if (_dataSource == DataSource.pod) {
        await loadFromPod();
      }
    } on BluelinkApiException catch (e) {
      debugPrint('[AppProvider] refresh BluelinkApiException: ${e.message}');
      _errorMessage = e.message;
      _state = AppState.error;
    } catch (e, st) {
      debugPrint('[AppProvider] refresh error: $e\n$st');
      _errorMessage = e.toString();
      _state = AppState.error;
    }
    _isRefreshing = false;
    notifyListeners();
  }

  void selectVehicle(int index) {
    _selectedVehicleIndex = index;
    notifyListeners();
  }

  Future<void> logout() async {
    await _storage.delete(key: 'bl_username');
    await _storage.delete(key: 'bl_password');
    await _storage.delete(key: 'bl_pin');
    _api.logout();
    _vehicles = [];
    _state = AppState.idle;
    _dataSource = DataSource.none;
    notifyListeners();
  }

  void loadMockData() {
    _vehicles = [Vehicle.mock()];
    _dataSource = DataSource.none;
    _state = AppState.loaded;
    notifyListeners();
  }

  void clearLoadedFile() {
    _loadedFilename = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ── Log book ──────────────────────────────────────────────────────────────

  void addLogEntry(LogEntry entry) {
    _logEntries = [entry, ..._logEntries];
    notifyListeners();
  }

  void updateLogEntry(LogEntry updated) {
    _logEntries = [
      for (final e in _logEntries) e.id == updated.id ? updated : e,
    ];
    notifyListeners();
  }

  void deleteLogEntry(String id) {
    _logEntries = _logEntries.where((e) => e.id != id).toList();
    notifyListeners();
  }

  Future<void> loadLogFromPod() async {
    _logLoading = true;
    notifyListeners();

    try {
      final raw = await PodService.loadLogEntries();
      _logEntries = raw.map(LogEntry.fromJson).toList();
    } catch (e) {
      debugPrint('[AppProvider] loadLogFromPod error: $e');
    } finally {
      _logLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveLogToPod() async {
    try {
      await PodService.saveLogEntries(
        _logEntries.map((e) => e.toJson()).toList(),
      );
    } catch (e) {
      debugPrint('[AppProvider] saveLogToPod error: $e');
    }
  }
}
