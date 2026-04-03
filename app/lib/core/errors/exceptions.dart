class AppException implements Exception {
  final String message;
  final String? code;

  AppException(this.message, [this.code]);

  @override
  String toString() =>
      'AppException: $message${code != null ? ' (code: $code)' : ''}';
}

class NetworkException extends AppException {
  NetworkException(super.message, [super.code]);

  @override
  String toString() =>
      'NetworkException: $message${code != null ? ' (code: $code)' : ''}';
}

class ServerException extends AppException {
  ServerException(super.message, [super.code]);

  @override
  String toString() =>
      'ServerException: $message${code != null ? ' (code: $code)' : ''}';
}

class AudioRecordingException extends AppException {
  AudioRecordingException(super.message, [super.code]);

  @override
  String toString() =>
      'AudioRecordingException: $message${code != null ? ' (code: $code)' : ''}';
}

class PermissionException extends AppException {
  PermissionException(super.message, [super.code]);

  @override
  String toString() =>
      'PermissionException: $message${code != null ? ' (code: $code)' : ''}';
}

class ValidationException extends AppException {
  ValidationException(super.message, [super.code]);

  @override
  String toString() =>
      'ValidationException: $message${code != null ? ' (code: $code)' : ''}';
}
