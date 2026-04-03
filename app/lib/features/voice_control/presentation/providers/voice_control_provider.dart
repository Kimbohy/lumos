import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/voice_command_result.dart';
import '../../domain/usecases/record_and_send_command.dart';
import '../../domain/usecases/stop_recording.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/logger.dart';

enum VoiceControlState { idle, recording, processing, success, error }

class VoiceControlProvider extends ChangeNotifier {
  RecordAndSendCommand _recordCommand;
  StopRecording _stopRecording;

  VoiceControlState _state = VoiceControlState.idle;
  VoiceCommandResult? _lastResult;
  String? _errorMessage;
  Timer? _recordingTimer;
  int _recordingDuration = 0;

  VoiceControlProvider(this._recordCommand, this._stopRecording);

  void updateDependencies(
    RecordAndSendCommand recordCommand,
    StopRecording stopRecording,
  ) {
    _recordCommand = recordCommand;
    _stopRecording = stopRecording;
    _lastResult = null;
    reset();
  }

  VoiceControlState get state => _state;
  VoiceCommandResult? get lastResult => _lastResult;
  String? get errorMessage => _errorMessage;
  int get recordingDuration => _recordingDuration;
  bool get isRecording => _state == VoiceControlState.recording;
  bool get isProcessing => _state == VoiceControlState.processing;
  bool get isIdle => _state == VoiceControlState.idle;

  Future<void> startRecording() async {
    if (_state == VoiceControlState.recording ||
        _state == VoiceControlState.processing) {
      Logger.warning('Already recording or processing', 'VoiceControlProvider');
      return;
    }

    try {
      Logger.info('Starting recording', 'VoiceControlProvider');
      _state = VoiceControlState.recording;
      _errorMessage = null;
      _lastResult = null;
      _recordingDuration = 0;
      notifyListeners();

      await _recordCommand.startRecording();

      // Start timer to track recording duration
      _startRecordingTimer();

      Logger.info('Recording started successfully', 'VoiceControlProvider');
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to start recording',
        'VoiceControlProvider',
        e,
        stackTrace,
      );
      _state = VoiceControlState.error;
      _errorMessage = _formatErrorMessage(e);
      notifyListeners();
    }
  }

  Future<void> stopRecording() async {
    if (_state != VoiceControlState.recording) {
      Logger.warning('Not currently recording', 'VoiceControlProvider');
      return;
    }

    // Check minimum recording duration
    if (_recordingDuration < AppConstants.minRecordingDurationMs) {
      Logger.warning('Recording too short', 'VoiceControlProvider');
      await cancelRecording();
      Logger.info(
        'Short tap ignored, keeping provider in idle state',
        'VoiceControlProvider',
      );
      return;
    }

    try {
      _stopRecordingTimer();

      Logger.info('Stopping recording and sending', 'VoiceControlProvider');
      _state = VoiceControlState.processing;
      notifyListeners();

      final result = await _stopRecording();

      _lastResult = result;

      if (result.status == CommandStatus.success) {
        _state = VoiceControlState.success;
        Logger.info('Command executed successfully', 'VoiceControlProvider');
      } else {
        _state = VoiceControlState.error;
        _errorMessage = result.message;
        Logger.warning(
          'Command failed: ${result.message}',
          'VoiceControlProvider',
        );
      }

      notifyListeners();

      // Auto reset to idle after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (_state == VoiceControlState.success ||
            _state == VoiceControlState.error) {
          reset();
        }
      });
    } catch (e, stackTrace) {
      _stopRecordingTimer();
      Logger.error(
        'Failed to stop recording',
        'VoiceControlProvider',
        e,
        stackTrace,
      );
      _state = VoiceControlState.error;
      _errorMessage = _formatErrorMessage(e);
      notifyListeners();

      // Auto reset after error
      Future.delayed(const Duration(seconds: 3), () {
        if (_state == VoiceControlState.error) {
          reset();
        }
      });
    }
  }

  Future<void> cancelRecording() async {
    if (_state != VoiceControlState.recording) {
      return;
    }

    try {
      _stopRecordingTimer();
      Logger.info('Cancelling recording', 'VoiceControlProvider');
      await _stopRecording.cancel();
      reset();
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to cancel recording',
        'VoiceControlProvider',
        e,
        stackTrace,
      );
      _state = VoiceControlState.error;
      _errorMessage = _formatErrorMessage(e);
      notifyListeners();
    }
  }

  void reset() {
    _stopRecordingTimer();
    _state = VoiceControlState.idle;
    _errorMessage = null;
    _recordingDuration = 0;
    notifyListeners();
  }

  void _startRecordingTimer() {
    _recordingDuration = 0;
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(milliseconds: 100), (
      timer,
    ) {
      _recordingDuration += 100;
      notifyListeners();

      // Auto stop at max duration
      if (_recordingDuration >=
          AppConstants.maxRecordingDurationSeconds * 1000) {
        Logger.info(
          'Max recording duration reached, auto-stopping',
          'VoiceControlProvider',
        );
        stopRecording();
      }
    });
  }

  void _stopRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
  }

  String _formatErrorMessage(Object error) {
    final errorStr = error.toString();
    // Remove exception class name prefix
    if (errorStr.contains(':')) {
      return errorStr.split(':').last.trim();
    }
    return errorStr;
  }

  @override
  void dispose() {
    _stopRecordingTimer();
    super.dispose();
  }
}
