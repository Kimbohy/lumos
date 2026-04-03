import 'dart:io';
import '../../domain/entities/voice_command_result.dart';
import '../../domain/repositories/voice_repository.dart';
import '../datasources/audio_recorder_datasource.dart';
import '../datasources/n8n_datasource.dart';
import '../../../../core/utils/logger.dart';

class VoiceRepositoryImpl implements VoiceRepository {
  final AudioRecorderDatasource _audioRecorder;
  final N8nDatasource _n8nDatasource;
  String? _currentRecordingPath;

  VoiceRepositoryImpl(this._audioRecorder, this._n8nDatasource);

  @override
  Future<void> startRecording() async {
    try {
      Logger.info('Starting recording from repository', 'VoiceRepository');
      await _audioRecorder.startRecording();
      Logger.info('Recording started successfully', 'VoiceRepository');
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to start recording',
        'VoiceRepository',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<VoiceCommandResult> stopRecordingAndSend() async {
    try {
      Logger.info('Stopping recording and sending to n8n', 'VoiceRepository');

      // Stop recording and get file path
      final audioPath = await _audioRecorder.stopRecording();
      _currentRecordingPath = audioPath;
      Logger.info('Recording stopped, file: $audioPath', 'VoiceRepository');

      // Send to n8n
      Logger.info('Sending audio to n8n', 'VoiceRepository');
      final responseModel = await _n8nDatasource.sendAudioCommand(audioPath);

      // Clean up audio file
      try {
        await File(audioPath).delete();
        Logger.info('Audio file deleted', 'VoiceRepository');
      } catch (e) {
        Logger.warning('Failed to delete audio file: $e', 'VoiceRepository');
      }

      // Convert to entity
      final result = responseModel.toEntity();
      Logger.info('Command result: ${result.status}', 'VoiceRepository');

      return result;
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to process voice command',
        'VoiceRepository',
        e,
        stackTrace,
      );

      // Clean up on error
      if (_currentRecordingPath != null) {
        try {
          await File(_currentRecordingPath!).delete();
        } catch (_) {}
      }

      rethrow;
    }
  }

  @override
  Future<bool> isRecording() async {
    try {
      return await _audioRecorder.isRecording();
    } catch (e) {
      Logger.error('Failed to check recording status', 'VoiceRepository', e);
      return false;
    }
  }

  @override
  Future<void> cancelRecording() async {
    try {
      Logger.info('Cancelling recording', 'VoiceRepository');
      await _audioRecorder.cancelRecording();
      _currentRecordingPath = null;
      Logger.info('Recording cancelled', 'VoiceRepository');
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to cancel recording',
        'VoiceRepository',
        e,
        stackTrace,
      );
      rethrow;
    }
  }
}
