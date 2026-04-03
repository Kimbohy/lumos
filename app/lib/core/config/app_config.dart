class AppConfig {
  final String n8nBaseUrl;
  final String flaskBaseUrl;

  const AppConfig({required this.n8nBaseUrl, required this.flaskBaseUrl});

  // Default configuration - can be overridden
  static const AppConfig defaultConfig = AppConfig(
    n8nBaseUrl: 'http://localhost:5678',
    flaskBaseUrl: 'http://localhost:5000',
  );

  // For production/different environments
  factory AppConfig.fromEnvironment({String? n8nUrl, String? flaskUrl}) {
    return AppConfig(
      n8nBaseUrl: n8nUrl ?? defaultConfig.n8nBaseUrl,
      flaskBaseUrl: flaskUrl ?? defaultConfig.flaskBaseUrl,
    );
  }

  AppConfig copyWith({String? n8nBaseUrl, String? flaskBaseUrl}) {
    return AppConfig(
      n8nBaseUrl: n8nBaseUrl ?? this.n8nBaseUrl,
      flaskBaseUrl: flaskBaseUrl ?? this.flaskBaseUrl,
    );
  }
}
