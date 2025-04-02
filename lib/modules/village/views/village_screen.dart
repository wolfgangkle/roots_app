import 'package:flutter/material.dart';
import '../models/village_model.dart';

class VillageScreen extends StatelessWidget {
  final VillageModel village;

  const VillageScreen({super.key, required this.village});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Village: ${village.name}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              '📍 Tile Location: ${village.tileX}, ${village.tileY}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Text('Resources:', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('🌲 Wood: ${village.wood}'),
                const SizedBox(width: 16),
                Text('🪨 Stone: ${village.stone}'),
                const SizedBox(width: 16),
                Text('🍞 Food: ${village.food}'),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              '🏗️ Buildings (Coming Soon)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('You’ll be able to manage buildings here.'),
          ],
        ),
      ),
    );
  }
}
