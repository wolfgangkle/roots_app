import 'package:flutter/material.dart';

class HeroGroupMovementControls extends StatelessWidget {
  final VoidCallback onClear;
  final VoidCallback onSend;
  final bool isSending;
  final int waypointCount;

  const HeroGroupMovementControls({
    super.key,
    required this.onClear,
    required this.onSend,
    required this.isSending,
    required this.waypointCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('📦 Current Queue: $waypointCount step(s)'),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: onClear,
              child: const Text('🗑️ Clear'),
            ),
            ElevatedButton(
              onPressed: isSending ? null : onSend,
              child: isSending
                  ? const Text('Sending...')
                  : const Text('🚀 Confirm Movement'),
            ),
          ],
        ),
      ],
    );
  }
}
