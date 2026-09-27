import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position> getCurrentLocation() async {
    final serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception(
        'Location services are disabled. Please enable GPS.',
      );
    }

    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission =
          await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception(
        'Location permission was denied.',
      );
    }

    if (permission ==
        LocationPermission.deniedForever) {
      throw Exception(
        'Location permission is permanently denied. Please enable it from device settings.',
      );
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }
}