import 'package:flutter/material.dart';
import 'package:firebase_functions/firebase_functions.dart';
import 'package:roots_app/modules/village/models/village_model.dart';
import 'package:roots_app/modules/village/data/building_definitions.dart';
import 'package:roots_app/modules/village/views/building_card.dart';

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
    final resources = village.simulatedResources;

    // Filter buildings by selected tag
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

        // Use formula-based dynamic cost
        final cost = def.getCostForLevel(nextLevel);

        final hasResources = (resources['wood'] ?? 0) >= (cost['wood'] ?? 0) &&
            (resources['stone'] ?? 0) >= (cost['stone'] ?? 0) &&
            (resources['food'] ?? 0) >= (cost['food'] ?? 0) &&
            (resources['iron'] ?? 0) >= (cost['iron'] ?? 0) &&
            (resources['gold'] ?? 0) >= (cost['gold'] ?? 0);

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
              final functions = FirebaseFunctions.instance;
              final callable =
              functions.httpsCallable('startBuildingUpgrade');
              await callable.call({
                'villageId': village.id,
                'buildingType': type,
              });

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
