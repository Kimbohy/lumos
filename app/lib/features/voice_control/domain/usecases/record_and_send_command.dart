import '../repositories/voice_repository.dart';

class RecordAndSendCommand {
  final VoiceRepository repository;

  RecordAndSendCommand(this.repository);

  Future<void> startRecording() async {
    return await repository.startRecording();
  }
}
