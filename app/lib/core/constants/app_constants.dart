class AppConstants {
  // App Info
  static const String appName = 'Lumos';
  static const String appVersion = '1.0.0';

  // Recording
  static const int maxRecordingDurationSeconds = 10;
  static const int minRecordingDurationMs = 500; // Minimum 0.5s recording

  // Timeouts
  static const int apiTimeoutSeconds = 30;
  static const int connectionTimeoutSeconds = 10;

  // Audio
  static const String audioFilePrefix = 'voice_command_';
  static const String audioFileExtension = 'm4a';
}
