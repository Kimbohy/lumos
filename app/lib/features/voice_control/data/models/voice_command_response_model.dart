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

    final bool isSuccess =
        (successValue is bool && successValue) ||
        status == 'executed' ||
        status == 'ok' ||
        (json['error'] == null && json['room'] != null);

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
