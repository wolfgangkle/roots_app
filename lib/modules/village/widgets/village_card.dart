import 'package:flutter/material.dart';
import '../models/village_model.dart';

class VillageCard extends StatelessWidget {
  final VillageModel village;
  final VoidCallback? onTap;

  const VillageCard({
    super.key,
    required this.village,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🏰 ${village.name}',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text('📍 Tile: ${village.tileX}, ${village.tileY}'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('🌲 ${village.wood}'),
                  const SizedBox(width: 12),
                  Text('🪨 ${village.stone}'),
                  const SizedBox(width: 12),
                  Text('🍞 ${village.food}'),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
