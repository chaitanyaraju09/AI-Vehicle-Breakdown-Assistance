class DtcModel {
  final int id;
  final String code;
  final String description;
  final String severity;
  final String possibleCauses;
  final String recommendedAction;

  DtcModel({
    required this.id,
    required this.code,
    required this.description,
    required this.severity,
    required this.possibleCauses,
    required this.recommendedAction,
  });

  factory DtcModel.fromJson(Map<String, dynamic> json) {
    return DtcModel(
      id: json['id'] as int,
      code: json['code'] as String,
      description: json['description'] as String,
      severity: json['severity'] as String,
      possibleCauses: json['possible_causes'] as String,
      recommendedAction: json['recommended_action'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'description': description,
      'severity': severity,
      'possible_causes': possibleCauses,
      'recommended_action': recommendedAction,
    };
  }
}
