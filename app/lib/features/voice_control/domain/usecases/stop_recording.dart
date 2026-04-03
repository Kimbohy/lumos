import '../entities/voice_command_result.dart';
import '../repositories/voice_repository.dart';

class StopRecording {
  final VoiceRepository repository;

  StopRecording(this.repository);

  Future<VoiceCommandResult> call() async {
    return await repository.stopRecordingAndSend();
  }

  Future<void> cancel() async {
    return await repository.cancelRecording();
  }
}
