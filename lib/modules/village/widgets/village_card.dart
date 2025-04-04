import 'package:flutter/material.dart';
import 'package:roots_app/modules/village/models/village_model.dart';
import 'package:roots_app/modules/village/widgets/upgrade_progress_indicator.dart';

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
    // ✅ Use simulated resource values based on time since last update
    final res = village.simulatedResources;

    final upgrade = village.currentBuildJob;

    final prodWood = village.buildings['woodcutter']?.productionPerHour ?? 0;
    final prodStone = village.buildings['quarry']?.productionPerHour ?? 0;
    final prodFood = village.buildings['farm']?.productionPerHour ?? 0;
    final prodIron = village.buildings['ironmine']?.productionPerHour ?? 0;
    final prodGold = village.buildings['goldmine']?.productionPerHour ?? 0;

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
              // 🏰 Name + Coordinates
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '🏰 ${village.name}',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text('📍 ${village.tileX}, ${village.tileY}'),
                ],
              ),
              const SizedBox(height: 8),

              // 📦 Resources with production
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('⛓️ Iron: ${res['iron']} (+$prodIron/h)'),
                  Text('🌲 Wood: ${res['wood']} (+$prodWood/h)'),
                  Text('🪨 Stone: ${res['stone']} (+$prodStone/h)'),
                  Text('🍞 Food: ${res['food']} (+$prodFood/h)'),
                  Text('💰 Gold: ${res['gold']} (+$prodGold/h)'),
                ],
              ),

              const SizedBox(height: 8),

              // ⏳ Upgrade progress
              if (upgrade != null)
                UpgradeProgressIndicator(
                  startedAt: upgrade.startedAt,
                  endsAt: upgrade.startedAt.add(upgrade.duration),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
