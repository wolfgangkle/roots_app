import 'package:flutter/material.dart';
import 'package:roots_app/modules/village/models/village_model.dart';
import 'package:roots_app/modules/village/data/building_definitions.dart';
import 'package:roots_app/modules/village/views/building_card.dart';
import 'package:roots_app/modules/village/services/village_service.dart';
import 'package:roots_app/modules/village/services/upgrade_timer.dart';

class BuildingTab extends StatelessWidget {
  final VillageModel village;
  final String selectedFilter;

  const BuildingTab({
    super.key,
    required this.village,
    required this.selectedFilter,
  });

  @override
  Widget build(BuildContext context) {
    final allUnlocked = village.getUnlockedBuildings();
    final currentUpgrade = village.currentBuildJob;
    final villageService = VillageService();

    // Filter buildings by selected tag.
    final filtered = selectedFilter == 'All'
        ? allUnlocked
        : allUnlocked.where((type) {
      final def = buildingDefinitions[type];
      if (def == null) return false;

      if (selectedFilter == 'Production' && def.baseProductionPerHour > 0) {
        return true;
      } else if (selectedFilter == 'Storage' &&
          def.displayName.contains('Storage')) {
        return true;
      }
      return false;
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final type = filtered[index];
        final def = buildingDefinitions[type]!;
        final level = village.buildings[type]?.level ?? 0;
        final nextLevel = level + 1;

        // Use formula-based dynamic cost.
        final cost = def.getCostForLevel(nextLevel);

        final hasResources = (village.wood >= (cost['wood'] ?? 0)) &&
            (village.stone >= (cost['stone'] ?? 0)) &&
            (village.food >= (cost['food'] ?? 0)) &&
            (village.iron >= (cost['iron'] ?? 0)) &&
            (village.gold >= (cost['gold'] ?? 0));

        final isAlreadyUpgrading = currentUpgrade != null;
        final canUpgrade = !isAlreadyUpgrading && hasResources;

        return BuildingCard(
          type: type,
          level: level,
          definition: def,
          village: village,
          onUpgrade: canUpgrade
              ? () async {
            try {
              await villageService.queueUpgradeForBuilding(
                villageId: village.id,
                buildingType: type,
                currentLevel: level,
              );

              // Start the dedicated upgrade timer.
              final upgradeTimer = UpgradeTimer(
                villageId: village.id,
                villageService: villageService,
              );
              upgradeTimer.start();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Upgrade started for $type')),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $e')),
              );
            }
          }
              : null,
        );
      },
    );
  }
}
