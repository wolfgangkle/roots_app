import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

class MiscToolsSection extends StatelessWidget {
  const MiscToolsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.schedule_send),
          label: const Text("📊 Start Guild Points Scheduler (1h)"),
          onPressed: () => _startGuildPointsScheduler(context),
        ),
      ],
    );
  }

  Future<void> _startGuildPointsScheduler(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final callable = FirebaseFunctions.instance.httpsCallable('startGuildPointsScheduler');
      final result = await callable.call({'delaySeconds': 30});
      messenger.showSnackBar(
        SnackBar(content: Text(result.data['message'] ?? 'Scheduled')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('❌ Error scheduling task: $e')),
      );
    }
  }
}
