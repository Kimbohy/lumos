abstract class Failure {
  final String message;
  final String? code;

  const Failure(this.message, [this.code]);

  @override
  String toString() => message;
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message, [super.code]);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, [super.code]);
}

class AudioRecordingFailure extends Failure {
  const AudioRecordingFailure(super.message, [super.code]);
}

class PermissionFailure extends Failure {
  const PermissionFailure(super.message, [super.code]);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, [super.code]);
}

class UnknownFailure extends Failure {
  const UnknownFailure(super.message, [super.code]);
}
