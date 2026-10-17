import '../config/app_config.dart';

class ApiEndpoints {
  // Configured via AppConfig (--dart-define=API_BASE_URL=...)
  static const String baseUrl = AppConfig.apiBaseUrl;

  // Authentication
  static const String register = '$baseUrl/auth/register';
  static const String login = '$baseUrl/auth/login';
  static const String me = '$baseUrl/auth/me';

  // DTC & AI Diagnosis
  static const String dtcLookup = '$baseUrl/dtc';
  static const String aiDiagnose = '$baseUrl/ai/diagnose';

  // Mechanics & Matching
  static const String mechanics = '$baseUrl/mechanics/';
  static const String matchMechanic = '$baseUrl/assistance/match';

  // Assistance Requests
  static const String assistance = '$baseUrl/assistance/';

  static String acceptRequest(int id) => '$baseUrl/assistance/$id/accept';

  static String startRequest(int id) => '$baseUrl/assistance/$id/start';

  static String completeRequest(int id) => '$baseUrl/assistance/$id/complete';
}
