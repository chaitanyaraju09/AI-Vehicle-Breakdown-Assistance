class AppConfig {
  AppConfig._();

  /// Base URL for the backend API.
  ///
  /// Can be overridden at build or run time via:
  /// `flutter run --dart-define=API_BASE_URL=http://<host>:<port>`
  ///
  /// Defaults to Android Emulator loopback `http://10.0.2.2:8000`.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  /// Application environment: development, staging, production
  static const String environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  static bool get isProduction => environment == 'production';
}
