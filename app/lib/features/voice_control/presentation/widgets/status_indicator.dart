import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/voice_control_provider.dart';

class StatusIndicator extends StatelessWidget {
  const StatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<VoiceControlProvider>(
      builder: (context, provider, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: _getStatusColor(context, provider).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _getStatusColor(context, provider),
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatusIcon(provider),
              const SizedBox(width: 12),
              Text(
                _getStatusText(provider),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: _getStatusColor(context, provider),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusIcon(VoiceControlProvider provider) {
    IconData icon;
    Color color;

    switch (provider.state) {
      case VoiceControlState.recording:
        icon = Icons.mic;
        color = Colors.red;
        break;
      case VoiceControlState.processing:
        icon = Icons.hourglass_empty;
        color = Colors.orange;
        break;
      case VoiceControlState.success:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case VoiceControlState.error:
        icon = Icons.error;
        color = Colors.red;
        break;
      default:
        icon = Icons.radio_button_unchecked;
        color = Colors.grey;
    }

    if (provider.isProcessing) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      );
    }

    return Icon(icon, color: color, size: 24);
  }

  String _getStatusText(VoiceControlProvider provider) {
    switch (provider.state) {
      case VoiceControlState.recording:
        return 'Recording...';
      case VoiceControlState.processing:
        return 'Processing...';
      case VoiceControlState.success:
        return 'Success!';
      case VoiceControlState.error:
        return 'Error';
      default:
        return 'Ready';
    }
  }

  Color _getStatusColor(BuildContext context, VoiceControlProvider provider) {
    switch (provider.state) {
      case VoiceControlState.recording:
        return Colors.red;
      case VoiceControlState.processing:
        return Colors.orange;
      case VoiceControlState.success:
        return Colors.green;
      case VoiceControlState.error:
        return Colors.red.shade800;
      default:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }
}
