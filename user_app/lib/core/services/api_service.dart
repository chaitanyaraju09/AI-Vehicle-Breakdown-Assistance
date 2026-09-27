import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_endpoints.dart';
import 'storage_service.dart';

class ApiService {
  final StorageService _storageService = StorageService();

  Future<Map<String, String>> _headers({
    bool authenticated = false,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (authenticated) {
      final token = await _storageService.getToken();

      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // =========================
  // AUTHENTICATION
  // =========================

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    String role = 'DRIVER',
  }) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.register),
      headers: await _headers(),
      body: jsonEncode({
        'email': email,
        'password': password,
        'full_name': fullName,
        'role': role,
      }),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.login),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      },
      body: {
        'username': email,
        'password': password,
      },
    );

    final data = _handleResponse(response);

    final token = data['access_token'];

    if (token != null) {
      await _storageService.saveToken(token.toString());
    }

    return data;
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await http.get(
      Uri.parse(ApiEndpoints.me),
      headers: await _headers(authenticated: true),
    );

    return _handleResponse(response);
  }

  Future<void> logout() async {
    await _storageService.deleteToken();
  }

  // =========================
  // AI DIAGNOSIS
  // =========================

  Future<Map<String, dynamic>> diagnoseSymptoms({
    required String symptomDescription,
    String? vehicleType,
  }) async {
    final body = <String, dynamic>{
      'symptom_description': symptomDescription,
    };

    if (vehicleType != null && vehicleType.isNotEmpty) {
      body['vehicle_type'] = vehicleType;
    }

    final response = await http.post(
      Uri.parse(ApiEndpoints.aiDiagnose),
      headers: await _headers(authenticated: true),
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  // =========================
  // DTC LOOKUP
  // =========================

  Future<Map<String, dynamic>> getDtcByCode(String code) async {
    final response = await http.get(
      Uri.parse('${ApiEndpoints.dtcLookup}/$code'),
      headers: await _headers(authenticated: true),
    );

    return _handleResponse(response);
  }

  // =========================
  // MECHANICS
  // =========================

  Future<List<dynamic>> getMechanics() async {
    final response = await http.get(
      Uri.parse(ApiEndpoints.mechanics),
      headers: await _headers(authenticated: true),
    );

    final data = _handleResponse(response);

    if (data is List) {
      return data;
    }

    return [];
  }

  // =========================
  // MECHANICS & MATCHING
  // =========================

  Future<Map<String, dynamic>> matchMechanics({
    required String driverName,
    required String phoneNumber,
    required String vehicleType,
    required String vehicleInfo,
    required String category,
    required String issueDescription,
    required double latitude,
    required double longitude,
  }) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.matchMechanic),
      headers: await _headers(authenticated: true),
      body: jsonEncode({
        'driver_name': driverName,
        'phone_number': phoneNumber,
        'vehicle_type': vehicleType,
        'vehicle_info': vehicleInfo,
        'category': category,
        'issue_description': issueDescription,
        'latitude': latitude,
        'longitude': longitude,
      }),
    );

    return _handleResponse(response);
  }

  // =========================
  // ASSISTANCE REQUEST
  // =========================

  Future<Map<String, dynamic>> createAssistanceRequest({
    required String driverName,
    required String phoneNumber,
    required String vehicleType,
    required String vehicleInfo,
    required String category,
    required String issueDescription,
    required double latitude,
    required double longitude,
  }) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.assistance),
      headers: await _headers(authenticated: true),
      body: jsonEncode({
        'driver_name': driverName,
        'phone_number': phoneNumber,
        'vehicle_type': vehicleType,
        'vehicle_info': vehicleInfo,
        'category': category,
        'issue_description': issueDescription,
        'latitude': latitude,
        'longitude': longitude,
      }),
    );

    return _handleResponse(response);
  }

  Future<List<dynamic>> getAssistanceRequests() async {
    final response = await http.get(
      Uri.parse(ApiEndpoints.assistance),
      headers: await _headers(authenticated: true),
    );

    final data = _handleResponse(response);

    if (data is List) {
      return data;
    }

    return [];
  }

  // =========================
  // MECHANIC REQUEST ACTIONS
  // =========================

  Future<Map<String, dynamic>> acceptRequest(int id) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.acceptRequest(id)),
      headers: await _headers(authenticated: true),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> startRequest(int id) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.startRequest(id)),
      headers: await _headers(authenticated: true),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> completeRequest(int id) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.completeRequest(id)),
      headers: await _headers(authenticated: true),
    );

    return _handleResponse(response);
  }

  // =========================
  // RESPONSE HANDLER
  // =========================

  dynamic _handleResponse(http.Response response) {
    dynamic data;

    try {
      data = jsonDecode(response.body);
    } catch (_) {
      data = {
        'detail': response.body,
      };
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    String message = 'Request failed';

    if (data is Map<String, dynamic>) {
      final detail = data['detail'];

      if (detail != null) {
        message = detail.toString();
      }
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: message,
    );
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({
    required this.statusCode,
    required this.message,
  });

  @override
  String toString() {
    return 'ApiException($statusCode): $message';
  }
}