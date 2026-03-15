import 'package:flutter/foundation.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/vehicle.dart';
import 'bluelink_service.dart';

enum AppState { idle, loading, loaded, error }

class AppProvider extends ChangeNotifier {
  final BluelinkService _api = BluelinkService();

  AppState _state = AppState.idle;
  String? _errorMessage;
  List<Vehicle> _vehicles = [];
  int _selectedVehicleIndex = 0;
  bool _isRefreshing = false;

  AppState get state => _state;
  String? get errorMessage => _errorMessage;
  List<Vehicle> get vehicles => _vehicles;
  Vehicle? get selectedVehicle =>
      _vehicles.isNotEmpty ? _vehicles[_selectedVehicleIndex] : null;
  bool get isAuthenticated => _api.isAuthenticated;
  bool get isRefreshing => _isRefreshing;

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('bl_username');
    final password = prefs.getString('bl_password');
    final pin = prefs.getString('bl_pin');
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

  Future<void> refresh() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    notifyListeners();
    try {
      await _api.refresh();
      _vehicles = await _api.getVehicles();
      _selectedVehicleIndex = 0;
      _state = AppState.loaded;
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
    notifyListeners();
  }

  void loadMockData() {
    _vehicles = [Vehicle.mock()];
    _state = AppState.loaded;
    notifyListeners();
  }
}
