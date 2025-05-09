import 'package:flutter/material.dart';

class RacePickerScreen extends StatelessWidget {
  final void Function(String selectedRace) onNext;

  const RacePickerScreen({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Your Race')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Choose your race.\n(This may later affect stats, abilities, and building names.)',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            /// 👤 Human
            Card(
              color: Colors.blue.shade50,
              child: ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Human'),
                subtitle: const Text('Balanced, adaptable — the default race'),
                onTap: () => onNext('Human'),
              ),
            ),

            const SizedBox(height: 16),

            /// 🪓 Dwarf
            Card(
              color: Colors.brown.shade100,
              child: ListTile(
                leading: const Icon(Icons.construction),
                title: const Text('Dwarf'),
                subtitle: const Text(
                    'Sturdy, industrious — excels in mining and defense'),
                onTap: () => onNext('Dwarf'),
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              'More races coming in future updates. 👀',
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
