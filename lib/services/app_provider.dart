import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vehicle.dart';
import 'bluelink_service.dart';
import 'pod_service.dart';

enum AppState { idle, loading, loaded, error }
enum DataSource { bluelink, pod, none }

class AppProvider extends ChangeNotifier {
  final BluelinkService _api = BluelinkService();

  AppState   _state      = AppState.idle;
  String?    _errorMessage;
  List<Vehicle> _vehicles = [];
  int        _selectedVehicleIndex = 0;
  bool       _isRefreshing = false;
  DataSource _dataSource   = DataSource.none;
  String?    _loadedFilename; // which pod file is currently loaded

  AppState   get state           => _state;
  String?    get errorMessage    => _errorMessage;
  List<Vehicle> get vehicles     => _vehicles;
  Vehicle?   get selectedVehicle =>
      _vehicles.isNotEmpty ? _vehicles[_selectedVehicleIndex] : null;
  bool       get isAuthenticated => _api.isAuthenticated;
  bool       get isRefreshing    => _isRefreshing;
  DataSource get dataSource      => _dataSource;
  String?    get loadedFilename  => _loadedFilename;
  bool       get hasData         => _vehicles.isNotEmpty;

  // ── Auto-login (desktop/bluelink) ────────────────────────────────────────

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('bl_username');
    final password = prefs.getString('bl_password');
    final pin      = prefs.getString('bl_pin');
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('bl_username', username);
      await prefs.setString('bl_password', password);
      await prefs.setString('bl_pin', pin);
      _vehicles = await _api.getVehicles();
      _selectedVehicleIndex = 0;
      _dataSource = DataSource.bluelink;
      _loadedFilename = null;
      _state = AppState.loaded;
      notifyListeners();
      return true;
    } on BluelinkApiException catch (e) {
      _state = AppState.error;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
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
      final data = await PodService.loadLatestStatus();
      if (data == null) {
        _state = AppState.error;
        _errorMessage = 'No status data found on your Solid Pod.\n'
            'Log in to Bluelink and save a snapshot first.';
        notifyListeners();
        return false;
      }
      return _loadVehicleFromMap(data, source: DataSource.pod);
    } catch (e) {
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
    } catch (e) {
      _state = AppState.error;
      _errorMessage = 'Pod load error: $e';
      notifyListeners();
      return false;
    }
  }

  bool _loadVehicleFromMap(Map<String, dynamic> data,
      {required DataSource source}) {
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

  // ── Save to pod ──────────────────────────────────────────────────────────

  Future<bool> saveToPod() async {
    if (_vehicles.isEmpty) return false;
    // Re-fetch raw data from Python to get full dict
    try {
      final rawJson = await _api.getRawVehicleJson();
      return PodService.saveStatusWithIndex(rawJson);
    } catch (e) {
      _errorMessage = 'Save error: $e';
      notifyListeners();
      return false;
    }
  }

  // ── Refresh ──────────────────────────────────────────────────────────────

  Future<void> refresh() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    notifyListeners();
    try {
      if (_dataSource == DataSource.bluelink && isAuthenticated) {
        await _api.refresh();
        _vehicles = await _api.getVehicles();
        _state = AppState.loaded;
      } else if (_dataSource == DataSource.pod) {
        await loadFromPod();
      }
    } catch (_) {}
    _isRefreshing = false;
    notifyListeners();
  }

  void selectVehicle(int index) {
    _selectedVehicleIndex = index;
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('bl_username');
    await prefs.remove('bl_password');
    await prefs.remove('bl_pin');
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

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
