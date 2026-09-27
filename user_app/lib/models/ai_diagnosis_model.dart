class AiDiagnosisModel {
  final String symptomDescription;
  final String aiSource;
  final List<DtcInfoModel> detectedDtcs;
  final String suggestedCategory;
  final String summary;

  AiDiagnosisModel({
    required this.symptomDescription,
    required this.aiSource,
    required this.detectedDtcs,
    required this.suggestedCategory,
    required this.summary,
  });

  factory AiDiagnosisModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final dtcsJson =
        json['detected_dtcs'] as List<dynamic>? ?? [];

    return AiDiagnosisModel(
      symptomDescription:
          json['symptom_description'] as String,
      aiSource: json['ai_source'] as String,
      detectedDtcs: dtcsJson
          .map(
            (item) => DtcInfoModel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
      suggestedCategory:
          json['suggested_category'] as String,
      summary: json['summary'] as String,
    );
  }
}

class DtcInfoModel {
  final String code;
  final String description;
  final String severity;
  final String possibleCauses;
  final String recommendedAction;

  DtcInfoModel({
    required this.code,
    required this.description,
    required this.severity,
    required this.possibleCauses,
    required this.recommendedAction,
  });

  factory DtcInfoModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return DtcInfoModel(
      code: json['code'] as String,
      description: json['description'] as String,
      severity: json['severity'] as String,
      possibleCauses:
          json['possible_causes'] as String,
      recommendedAction:
          json['recommended_action'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'description': description,
      'severity': severity,
      'possible_causes': possibleCauses,
      'recommended_action': recommendedAction,
    };
  }
}