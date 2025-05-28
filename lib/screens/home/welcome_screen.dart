import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.auto_awesome, // ✨ magical vibe
              size: 64,
              color: Colors.teal,
            ),
            const SizedBox(height: 24),
            const Text(
              "Welcome to ROOTS!",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Click on a village or hero to begin your journey.\nYour destiny awaits, adventurer.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Optionally focus the user on a help screen or guide in future
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("No hero selected yet 🧙‍♂️")),
                );
              },
              icon: const Icon(Icons.explore),
              label: const Text("Explore your realm"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
