import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/voice_control_provider.dart';
import '../../../../core/constants/app_constants.dart';

class RecordButton extends StatefulWidget {
  const RecordButton({super.key});

  @override
  State<RecordButton> createState() => _RecordButtonState();
}

class _RecordButtonState extends State<RecordButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VoiceControlProvider>(
      builder: (context, provider, child) {
        final isRecording = provider.isRecording;
        final isProcessing = provider.isProcessing;

        return GestureDetector(
          onTapDown: isProcessing ? null : (_) => _handleTapDown(provider),
          onTapUp: isRecording ? (_) => _handleTapUp(provider) : null,
          onTapCancel: isRecording ? () => _handleCancel(provider) : null,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: isRecording ? _pulseAnimation.value : 1.0,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getButtonColor(context, provider),
                    boxShadow: [
                      BoxShadow(
                        color: _getButtonColor(
                          context,
                          provider,
                        ).withValues(alpha: 0.4),
                        blurRadius: isRecording ? 20 : 10,
                        spreadRadius: isRecording ? 5 : 0,
                      ),
                    ],
                  ),
                  child: Center(child: _buildButtonContent(context, provider)),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _handleTapDown(VoiceControlProvider provider) {
    if (provider.isIdle) {
      provider.startRecording();
    }
  }

  void _handleTapUp(VoiceControlProvider provider) {
    if (provider.isRecording) {
      provider.stopRecording();
    }
  }

  void _handleCancel(VoiceControlProvider provider) {
    if (provider.isRecording) {
      provider.cancelRecording();
    }
  }

  Color _getButtonColor(BuildContext context, VoiceControlProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (provider.state) {
      case VoiceControlState.recording:
        return Colors.red;
      case VoiceControlState.processing:
        return colorScheme.tertiary;
      case VoiceControlState.success:
        return Colors.green;
      case VoiceControlState.error:
        return Colors.red.shade800;
      default:
        return colorScheme.primary;
    }
  }

  Widget _buildButtonContent(
    BuildContext context,
    VoiceControlProvider provider,
  ) {
    final textTheme = Theme.of(context).textTheme;

    if (provider.isProcessing) {
      return const CircularProgressIndicator(
        color: Colors.white,
        strokeWidth: 3,
      );
    }

    if (provider.isRecording) {
      final duration = provider.recordingDuration / 1000;
      final remaining = AppConstants.maxRecordingDurationSeconds - duration;
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.mic, color: Colors.white, size: 40),
          const SizedBox(height: 8),
          Text(
            '${remaining.toStringAsFixed(1)}s',
            style: textTheme.bodySmall?.copyWith(color: Colors.white),
          ),
        ],
      );
    }

    IconData icon;
    switch (provider.state) {
      case VoiceControlState.success:
        icon = Icons.check;
        break;
      case VoiceControlState.error:
        icon = Icons.close;
        break;
      default:
        icon = Icons.mic;
    }

    return Icon(icon, color: Colors.white, size: 48);
  }
}
