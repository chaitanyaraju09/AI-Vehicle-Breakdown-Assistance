class AppConfig {
  AppConfig._();

  /// Base URL for the backend API.
  ///
  /// Can be overridden at build or run time via:
  /// `flutter run --dart-define=API_BASE_URL=http://<host>:<port>`
  ///
  /// Defaults to Android Emulator loopback `http://10.0.2.2:8000`.
  /// For physical devices on LAN, specify e.g. `http://192.168.1.100:8000`.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  /// Google Maps API key passed via compile-time definition:
  /// `--dart-define=GOOGLE_MAPS_API_KEY=AIza...`
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  /// Current application environment: development, staging, production
  static const String environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  static bool get isProduction => environment == 'production';
}
