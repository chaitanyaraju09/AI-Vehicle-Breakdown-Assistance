class AssistanceRequestModel {
  final int id;
  final String driverName;
  final String phoneNumber;
  final String vehicleType;
  final String vehicleInfo;
  final String category;
  final String issueDescription;
  final double latitude;
  final double longitude;
  final String status;
  final int? mechanicId;
  final DateTime createdAt;

  AssistanceRequestModel({
    required this.id,
    required this.driverName,
    required this.phoneNumber,
    required this.vehicleType,
    required this.vehicleInfo,
    required this.category,
    required this.issueDescription,
    required this.latitude,
    required this.longitude,
    required this.status,
    this.mechanicId,
    required this.createdAt,
  });

  factory AssistanceRequestModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return AssistanceRequestModel(
      id: json['id'] as int,
      driverName: json['driver_name'] as String,
      phoneNumber: json['phone_number'] as String,
      vehicleType: json['vehicle_type'] as String,
      vehicleInfo: json['vehicle_info'] as String,
      category: json['category'] as String,
      issueDescription: json['issue_description'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      status: json['status'] as String,
      mechanicId: json['mechanic_id'] as int?,
      createdAt: DateTime.parse(
        json['created_at'] as String,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driver_name': driverName,
      'phone_number': phoneNumber,
      'vehicle_type': vehicleType,
      'vehicle_info': vehicleInfo,
      'category': category,
      'issue_description': issueDescription,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'mechanic_id': mechanicId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}