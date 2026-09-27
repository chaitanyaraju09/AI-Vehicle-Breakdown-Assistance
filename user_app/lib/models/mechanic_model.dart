class MechanicModel {
  final int id;
  final int? userId;
  final String name;
  final String phoneNumber;
  final String serviceCategories;
  final String supportedVehicleTypes;
  final double latitude;
  final double longitude;
  final bool isAvailable;
  final double rating;
  final int experienceYears;
  final String status;

  MechanicModel({
    required this.id,
    this.userId,
    required this.name,
    required this.phoneNumber,
    required this.serviceCategories,
    required this.supportedVehicleTypes,
    required this.latitude,
    required this.longitude,
    required this.isAvailable,
    required this.rating,
    required this.experienceYears,
    required this.status,
  });

  factory MechanicModel.fromJson(Map<String, dynamic> json) {
    return MechanicModel(
      id: json['id'] as int,
      userId: json['user_id'] as int?,
      name: json['name'] as String,
      phoneNumber: json['phone_number'] as String,
      serviceCategories: json['service_categories'] as String,
      supportedVehicleTypes: json['supported_vehicle_types'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      isAvailable: json['is_available'] as bool,
      rating: (json['rating'] as num).toDouble(),
      experienceYears: json['experience_years'] as int,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'phone_number': phoneNumber,
      'service_categories': serviceCategories,
      'supported_vehicle_types': supportedVehicleTypes,
      'latitude': latitude,
      'longitude': longitude,
      'is_available': isAvailable,
      'rating': rating,
      'experience_years': experienceYears,
      'status': status,
    };
  }
}