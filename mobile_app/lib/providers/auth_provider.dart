import 'package:flutter/foundation.dart';

import '../core/services/api_service.dart';
import '../core/services/storage_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  // =========================
  // GETTERS
  // =========================

  UserModel? get user => _user;

  bool get isLoading => _isLoading;

  bool get isLoggedIn => _user != null;

  String? get errorMessage => _errorMessage;

  // =========================
  // LOGIN
  // =========================

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _apiService.login(
        email: email,
        password: password,
      );

      final userData = await _apiService.getCurrentUser();

      _user = UserModel.fromJson(userData);

      _setLoading(false);
      notifyListeners();

      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Unable to login. Please try again.';
    }

    _setLoading(false);
    notifyListeners();

    return false;
  }

  // =========================
  // REGISTER
  // =========================

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    String role = 'DRIVER',
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _apiService.register(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
      );

      _setLoading(false);
      notifyListeners();

      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage =
          'Unable to create account. Please try again.';
    }

    _setLoading(false);
    notifyListeners();

    return false;
  }

  // =========================
  // CHECK EXISTING LOGIN
  // =========================

  Future<bool> checkExistingLogin() async {
    _setLoading(true);
    _clearError();

    try {
      final hasToken = await _storageService.hasToken();

      if (!hasToken) {
        _setLoading(false);
        notifyListeners();
        return false;
      }

      final userData = await _apiService.getCurrentUser();

      _user = UserModel.fromJson(userData);

      _setLoading(false);
      notifyListeners();

      return true;
    } catch (_) {
      await _storageService.deleteToken();
      _user = null;
    }

    _setLoading(false);
    notifyListeners();

    return false;
  }

  // =========================
  // LOGOUT
  // =========================

  Future<void> logout() async {
    await _apiService.logout();

    _user = null;
    _clearError();

    notifyListeners();
  }

  // =========================
  // ERROR HANDLING
  // =========================

  void clearError() {
    _clearError();
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  // =========================
  // LOADING
  // =========================

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}