class ApiEndpoints {
  // Android Emulator → FastAPI running on Windows
  static const String baseUrl = 'http://10.0.2.2:8000';

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

  static String acceptRequest(int id) =>
      '$baseUrl/assistance/$id/accept';

  static String startRequest(int id) =>
      '$baseUrl/assistance/$id/start';

  static String completeRequest(int id) =>
      '$baseUrl/assistance/$id/complete';
}