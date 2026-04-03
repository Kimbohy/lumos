import 'package:flutter/material.dart';
import '../widgets/record_button.dart';
import '../widgets/status_indicator.dart';
import '../widgets/result_display.dart';

class VoiceControlPage extends StatelessWidget {
  const VoiceControlPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),

          // Status Indicator
          const Center(child: StatusIndicator()),

          const SizedBox(height: 40),

          // Record Button
          const Center(child: RecordButton()),

          const SizedBox(height: 40),

          // Result Display
          const ResultDisplay(),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
