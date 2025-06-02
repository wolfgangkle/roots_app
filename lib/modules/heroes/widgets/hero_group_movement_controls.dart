import 'package:flutter/material.dart';

class HeroGroupMovementControls extends StatelessWidget {
  final VoidCallback onClear;
  final VoidCallback onSend;
  final VoidCallback? onCancelMovement;
  final bool isSending;
  final int waypointCount;

  const HeroGroupMovementControls({
    super.key,
    required this.onClear,
    required this.onSend,
    this.onCancelMovement,
    required this.isSending,
    required this.waypointCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('📦 Current Queue: $waypointCount step(s)'),
        const SizedBox(height: 12),

        // Cancel movement button (if available)
        if (onCancelMovement != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: ElevatedButton.icon(
              onPressed: isSending ? null : onCancelMovement,
              icon: const Icon(Icons.undo),
              label: const Text('↩️ Cancel & Return'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
            ),
          ),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: isSending ? null : onClear,
              icon: const Icon(Icons.clear),
              label: const Text('🗑️ Clear'),
            ),
            ElevatedButton.icon(
              onPressed: isSending ? null : onSend,
              icon: const Icon(Icons.send),
              label: isSending
                  ? const Text('Sending...')
                  : const Text('🚀 Confirm Movement'),
            ),
          ],
        ),
      ],
    );
  }
}
