import '../../domain/entities/voice_command_result.dart';

class VoiceCommandResponseModel {
  final String? transcription;
  final String? room;
  final String? action;
  final String? message;
  final String? error;
  final bool success;

  const VoiceCommandResponseModel({
    this.transcription,
    this.room,
    this.action,
    this.message,
    this.error,
    required this.success,
  });

  factory VoiceCommandResponseModel.fromJson(Map<String, dynamic> json) {
    // Handle different response formats from n8n/Flask
    final dynamic successValue = json['success'];
    final String? status = json['status']?.toString().toLowerCase();
    final String? message = json['message']?.toString().toLowerCase();

    final bool hasExplicitFailure =
        (successValue is bool && !successValue) ||
        status == 'error' ||
        status == 'failed' ||
        status == 'failure' ||
        json['error'] != null;

    final bool hasAsyncAckMessage =
        message != null &&
        (message.contains('workflow was started') ||
            message.contains('workflow started') ||
            message.contains('accepted') ||
            message.contains('queued'));

    final bool isSuccess =
        !hasExplicitFailure &&
        ((successValue is bool && successValue) ||
            status == 'executed' ||
            status == 'ok' ||
            (json['room'] != null && json['action'] != null) ||
            hasAsyncAckMessage);

    return VoiceCommandResponseModel(
      transcription: json['transcription'] as String?,
      room: json['room'] as String?,
      action: json['action'] as String?,
      message: json['message'] as String?,
      error: json['error'] as String?,
      success: isSuccess,
    );
  }

  VoiceCommandResult toEntity() {
    if (success) {
      return VoiceCommandResult.success(
        transcription: transcription,
        room: room,
        action: action,
        message: message ?? 'Command executed successfully',
      );
    } else {
      return VoiceCommandResult.error(
        transcription: transcription,
        message: error ?? message ?? 'Unknown error occurred',
      );
    }
  }
}
