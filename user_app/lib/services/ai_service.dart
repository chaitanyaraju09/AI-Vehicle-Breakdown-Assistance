import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config/app_config.dart';

class AiService {
  static const String baseUrl = AppConfig.apiBaseUrl;

  Future<Map<String, dynamic>> diagnoseSymptoms({
    required String symptomDescription,
    String? vehicleType,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ai/diagnose'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'symptom_description': symptomDescription,
        'vehicle_type': vehicleType,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    try {
      final errorBody = jsonDecode(response.body);

      throw Exception(
        errorBody['detail']?.toString() ??
            'AI diagnosis failed with status ${response.statusCode}',
      );
    } catch (_) {
      throw Exception('AI diagnosis failed with status ${response.statusCode}');
    }
  }
}
