import 'package:flutter/foundation.dart';

import '../core/services/api_service.dart';
import '../models/ai_diagnosis_model.dart';
import '../models/assistance_request_model.dart';
import '../models/mechanic_match_model.dart';

class AssistanceProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  // =========================
  // STATE
  // =========================

  bool _isLoading = false;
  String? _errorMessage;

  List<AssistanceRequestModel> _requests = [];
  AssistanceRequestModel? _currentRequest;

  MechanicMatchResultModel? _matchResult;

  AiDiagnosisModel? _diagnosis;

  double? _latitude;
  double? _longitude;

  // =========================
  // GETTERS
  // =========================

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  List<AssistanceRequestModel> get requests => _requests;

  AssistanceRequestModel? get currentRequest => _currentRequest;

  MechanicMatchResultModel? get matchResult => _matchResult;

  AiDiagnosisModel? get diagnosis => _diagnosis;

  double? get latitude => _latitude;

  double? get longitude => _longitude;

  // =========================
  // LOCATION
  // =========================

  void setLocation({
    required double latitude,
    required double longitude,
  }) {
    _latitude = latitude;
    _longitude = longitude;

    notifyListeners();
  }

  // =========================
  // AI DIAGNOSIS
  // =========================

  Future<bool> diagnoseSymptoms({
    required String symptomDescription,
    String? vehicleType,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.diagnoseSymptoms(
        symptomDescription: symptomDescription,
        vehicleType: vehicleType,
      );

      _diagnosis = AiDiagnosisModel.fromJson(
        response,
      );

      _setLoading(false);
      notifyListeners();

      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage =
          'Unable to analyze symptoms. Please try again.';
    }

    _setLoading(false);
    notifyListeners();

    return false;
  }

  // =========================
  // MECHANIC MATCHING
  // =========================

  Future<bool> matchMechanics({
    required String driverName,
    required String phoneNumber,
    required String vehicleType,
    required String vehicleInfo,
    required String category,
    required String issueDescription,
    required double latitude,
    required double longitude,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.matchMechanics(
        driverName: driverName,
        phoneNumber: phoneNumber,
        vehicleType: vehicleType,
        vehicleInfo: vehicleInfo,
        category: category,
        issueDescription: issueDescription,
        latitude: latitude,
        longitude: longitude,
      );

      _matchResult = MechanicMatchResultModel.fromJson(
        response,
      );

      _setLoading(false);
      notifyListeners();

      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage =
          'Unable to find nearby mechanics.';
    }

    _setLoading(false);
    notifyListeners();

    return false;
  }

  // =========================
  // CREATE ASSISTANCE REQUEST
  // =========================

  Future<bool> createRequest({
    required String driverName,
    required String phoneNumber,
    required String vehicleType,
    required String vehicleInfo,
    required String category,
    required String issueDescription,
    required double latitude,
    required double longitude,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response =
          await _apiService.createAssistanceRequest(
        driverName: driverName,
        phoneNumber: phoneNumber,
        vehicleType: vehicleType,
        vehicleInfo: vehicleInfo,
        category: category,
        issueDescription: issueDescription,
        latitude: latitude,
        longitude: longitude,
      );

      _currentRequest =
          AssistanceRequestModel.fromJson(response);

      _setLoading(false);
      notifyListeners();

      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage =
          'Unable to create assistance request.';
    }

    _setLoading(false);
    notifyListeners();

    return false;
  }

  // =========================
  // LOAD ASSISTANCE REQUESTS
  // =========================

  Future<bool> loadRequests() async {
    _setLoading(true);
    _clearError();

    try {
      final response =
          await _apiService.getAssistanceRequests();

      _requests = response
          .map(
            (item) =>
                AssistanceRequestModel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList();

      _setLoading(false);
      notifyListeners();

      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage =
          'Unable to load assistance requests.';
    }

    _setLoading(false);
    notifyListeners();

    return false;
  }

  // =========================
  // ACCEPT REQUEST
  // =========================

  Future<bool> acceptRequest(int requestId) async {
    _setLoading(true);
    _clearError();

    try {
      final response =
          await _apiService.acceptRequest(requestId);

      _currentRequest =
          AssistanceRequestModel.fromJson(response);

      await loadRequests();

      _setLoading(false);
      notifyListeners();

      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage =
          'Unable to accept assistance request.';
    }

    _setLoading(false);
    notifyListeners();

    return false;
  }

  // =========================
  // START REQUEST
  // =========================

  Future<bool> startRequest(int requestId) async {
    _setLoading(true);
    _clearError();

    try {
      final response =
          await _apiService.startRequest(requestId);

      _currentRequest =
          AssistanceRequestModel.fromJson(response);

      await loadRequests();

      _setLoading(false);
      notifyListeners();

      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage =
          'Unable to start assistance request.';
    }

    _setLoading(false);
    notifyListeners();

    return false;
  }

  // =========================
  // COMPLETE REQUEST
  // =========================

  Future<bool> completeRequest(int requestId) async {
    _setLoading(true);
    _clearError();

    try {
      final response =
          await _apiService.completeRequest(requestId);

      _currentRequest =
          AssistanceRequestModel.fromJson(response);

      await loadRequests();

      _setLoading(false);
      notifyListeners();

      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage =
          'Unable to complete assistance request.';
    }

    _setLoading(false);
    notifyListeners();

    return false;
  }

  // =========================
  // CLEAR CURRENT REQUEST
  // =========================

  void clearCurrentRequest() {
    _currentRequest = null;
    _matchResult = null;
    _diagnosis = null;

    notifyListeners();
  }

  // =========================
  // CLEAR ERROR
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