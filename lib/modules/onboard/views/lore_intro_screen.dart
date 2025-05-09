import 'package:flutter/material.dart';

class LoreIntroScreen extends StatelessWidget {
  final VoidCallback onNext;

  const LoreIntroScreen({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '🌿 Welcome to ROOTS 🌿',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const Text(
              'In a world torn by ancient magic and forgotten wars, '
              'you are one of the last to awaken under the Heartroot’s blessing.\n\n'
              'Establish your village, gather companions, and prepare for the trials to come.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: onNext,
              child: const Text('Begin Your Journey'),
            ),
          ],
        ),
      ),
    );
  }
}
