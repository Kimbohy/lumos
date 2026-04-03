enum CommandStatus {
  success,
  error,
  unknown;

  @override
  String toString() => name;
}

class VoiceCommandResult {
  final String? transcription;
  final String? room;
  final String? action;
  final String? message;
  final CommandStatus status;
  final DateTime timestamp;

  const VoiceCommandResult({
    this.transcription,
    this.room,
    this.action,
    this.message,
    required this.status,
    required this.timestamp,
  });

  factory VoiceCommandResult.success({
    String? transcription,
    String? room,
    String? action,
    String? message,
  }) {
    return VoiceCommandResult(
      transcription: transcription,
      room: room,
      action: action,
      message: message ?? 'Command executed successfully',
      status: CommandStatus.success,
      timestamp: DateTime.now(),
    );
  }

  factory VoiceCommandResult.error({
    String? transcription,
    required String message,
  }) {
    return VoiceCommandResult(
      transcription: transcription,
      message: message,
      status: CommandStatus.error,
      timestamp: DateTime.now(),
    );
  }

  @override
  String toString() => 'VoiceCommandResult(status: $status, message: $message)';
}
