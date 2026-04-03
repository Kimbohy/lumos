import '../entities/voice_command_result.dart';

abstract class VoiceRepository {
  /// Start recording audio
  Future<void> startRecording();

  /// Stop recording and send the audio to n8n
  Future<VoiceCommandResult> stopRecordingAndSend();

  /// Check if currently recording
  Future<bool> isRecording();

  /// Cancel recording without sending
  Future<void> cancelRecording();
}
