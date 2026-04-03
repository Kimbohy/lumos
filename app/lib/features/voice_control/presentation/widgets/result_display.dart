import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/voice_control_provider.dart';

class ResultDisplay extends StatelessWidget {
  const ResultDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<VoiceControlProvider>(
      builder: (context, provider, child) {
        if (provider.state == VoiceControlState.idle) {
          return _buildInstructions(context);
        }

        if (provider.state == VoiceControlState.error &&
            provider.errorMessage != null) {
          return _buildErrorCard(context, provider.errorMessage!);
        }

        if (provider.lastResult != null) {
          return _buildResultCard(context, provider);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildInstructions(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.touch_app,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Press and Hold to Record',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Hold the microphone button while speaking your command. Release when done.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 20,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Example: "Turn on the light in Paul\'s bedroom"',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, String errorMessage) {
    return Card(
      elevation: 2,
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade700),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.red.shade900,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.red.shade800),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, VoiceControlProvider provider) {
    final result = provider.lastResult!;
    final isSuccess = provider.state == VoiceControlState.success;

    return Card(
      elevation: 2,
      color: isSuccess ? Colors.green.shade50 : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : Icons.error,
                  color: isSuccess
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isSuccess ? 'Command Executed' : 'Command Failed',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: isSuccess
                          ? Colors.green.shade900
                          : Colors.red.shade900,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (result.transcription != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              _buildInfoRow(
                context,
                Icons.mic,
                'Transcription',
                result.transcription!,
                isSuccess,
              ),
            ],
            if (result.room != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                context,
                Icons.room,
                'Room',
                result.room!,
                isSuccess,
              ),
            ],
            if (result.action != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                context,
                Icons.flash_on,
                'Action',
                result.action!.toUpperCase(),
                isSuccess,
              ),
            ],
            if (result.message != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                context,
                Icons.info_outline,
                'Message',
                result.message!,
                isSuccess,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    bool isSuccess,
  ) {
    final color = isSuccess ? Colors.green.shade800 : Colors.red.shade800;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color.withValues(alpha: 0.7),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: color),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
