import 'dart:io';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/logger.dart';

class AudioRecorderDatasource {
  final AudioRecorder _recorder = AudioRecorder();
  String? _currentRecordingPath;

  Future<void> startRecording() async {
    try {
      Logger.info('Checking microphone permission', 'AudioRecorder');

      // Use the recorder plugin permission flow for cross-platform support.
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        throw PermissionException('Microphone permission denied');
      }

      // Check if already recording
      if (await _recorder.isRecording()) {
        Logger.warning(
          'Already recording, stopping previous recording',
          'AudioRecorder',
        );
        await _recorder.stop();
      }

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath =
          '${tempDir.path}/${AppConstants.audioFilePrefix}$timestamp.${AppConstants.audioFileExtension}';

      Logger.info(
        'Starting recording to: $_currentRecordingPath',
        'AudioRecorder',
      );

      // Start recording
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc, // m4a format
          numChannels: 1,
          sampleRate: 16000,
        ),
        path: _currentRecordingPath!,
      );

      Logger.info('Recording started successfully', 'AudioRecorder');
    } catch (e, stackTrace) {
      Logger.error('Failed to start recording', 'AudioRecorder', e, stackTrace);
      if (e is PermissionException) {
        rethrow;
      }

      if (e is ProcessException) {
        throw AudioRecordingException(_formatNativeDependencyError(e));
      }

      throw AudioRecordingException('Failed to start recording: $e');
    }
  }

  String _formatNativeDependencyError(ProcessException e) {
    if (!Platform.isLinux) {
      return 'Failed to start recording: $e';
    }

    final executable = e.executable.trim();

    if (executable == 'fmedia') {
      return 'Missing Linux audio dependency: fmedia. Install fmedia and ensure it is available in PATH.';
    }

    if (executable == 'parecord') {
      return 'Missing Linux audio dependency: parecord. Install pulseaudio-utils and ensure parecord is available in PATH.';
    }

    return 'Missing Linux audio dependency: $executable. Install it and ensure it is available in PATH.';
  }

  Future<String> stopRecording() async {
    try {
      Logger.info('Stopping recording', 'AudioRecorder');

      if (!await _recorder.isRecording()) {
        throw AudioRecordingException('Not currently recording');
      }

      final path = await _recorder.stop();

      if (path == null || !await File(path).exists()) {
        throw AudioRecordingException('Recording file not found');
      }

      // Check file size
      final file = File(path);
      final fileSize = await file.length();
      Logger.info(
        'Recording stopped. File size: $fileSize bytes',
        'AudioRecorder',
      );

      if (fileSize < 1000) {
        // Less than 1KB
        await file.delete();
        throw AudioRecordingException('Recording too short or empty');
      }

      return path;
    } catch (e, stackTrace) {
      Logger.error('Failed to stop recording', 'AudioRecorder', e, stackTrace);
      if (e is AudioRecordingException) {
        rethrow;
      }
      throw AudioRecordingException('Failed to stop recording: $e');
    }
  }

  Future<bool> isRecording() async {
    try {
      return await _recorder.isRecording();
    } catch (e) {
      Logger.error('Failed to check recording status', 'AudioRecorder', e);
      return false;
    }
  }

  Future<void> cancelRecording() async {
    try {
      Logger.info('Cancelling recording', 'AudioRecorder');

      if (await _recorder.isRecording()) {
        final path = await _recorder.stop();

        // Delete the recording file
        if (path != null && await File(path).exists()) {
          await File(path).delete();
          Logger.info('Recording file deleted', 'AudioRecorder');
        }
      }
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to cancel recording',
        'AudioRecorder',
        e,
        stackTrace,
      );
      throw AudioRecordingException('Failed to cancel recording: $e');
    }
  }

  Future<void> dispose() async {
    try {
      await _recorder.dispose();
    } catch (e) {
      Logger.error('Failed to dispose recorder', 'AudioRecorder', e);
    }
  }
}
