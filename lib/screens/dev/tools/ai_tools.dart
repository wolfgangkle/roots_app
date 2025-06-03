import 'package:flutter/material.dart';
import 'package:roots_app/screens/dev/seed_functions.dart';

class AIToolsSection extends StatelessWidget {
  const AIToolsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.auto_awesome),
          label: const Text("🌿 Generate Peaceful AI Event"),
          onPressed: () => triggerPeacefulAIEvent(context),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          icon: const Icon(Icons.auto_awesome_motion),
          label: const Text("⚔️ Generate Combat AI Event"),
          onPressed: () => triggerCombatAIEvent(context),
        ),
      ],
    );
  }
}
