class MechanicMatchModel {
  final int mechanicId;
  final String mechanicName;
  final double distanceKm;
  final String distanceDisplay;
  final int estimatedEtaMinutes;
  final double rating;
  final int experienceYears;
  final double aiScore;

  MechanicMatchModel({
    required this.mechanicId,
    required this.mechanicName,
    required this.distanceKm,
    required this.distanceDisplay,
    required this.estimatedEtaMinutes,
    required this.rating,
    required this.experienceYears,
    required this.aiScore,
  });

  factory MechanicMatchModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return MechanicMatchModel(
      mechanicId: json['mechanic_id'] as int,
      mechanicName: json['mechanic_name'] as String,
      distanceKm: (json['distance_km'] as num).toDouble(),
      distanceDisplay: json['distance_display'] as String,
      estimatedEtaMinutes:
          json['estimated_eta_minutes'] as int,
      rating: (json['rating'] as num).toDouble(),
      experienceYears: json['experience_years'] as int,
      aiScore: (json['ai_score'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mechanic_id': mechanicId,
      'mechanic_name': mechanicName,
      'distance_km': distanceKm,
      'distance_display': distanceDisplay,
      'estimated_eta_minutes': estimatedEtaMinutes,
      'rating': rating,
      'experience_years': experienceYears,
      'ai_score': aiScore,
    };
  }
}

class MechanicMatchResultModel {
  final String recommendationMethod;
  final List<MechanicMatchModel> matches;

  MechanicMatchResultModel({
    required this.recommendationMethod,
    required this.matches,
  });

  factory MechanicMatchResultModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final matchesJson = json['matches'] as List<dynamic>? ?? [];

    return MechanicMatchResultModel(
      recommendationMethod:
          json['recommendation_method'] as String,
      matches: matchesJson
          .map(
            (item) => MechanicMatchModel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }
}