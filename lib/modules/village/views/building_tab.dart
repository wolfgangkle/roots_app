import 'package:flutter/material.dart';
import '../models/village_model.dart';
import '../data/building_definitions.dart';
import 'building_card.dart';


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

    // Filter buildings by selected type
    final filtered = selectedFilter == 'All'
        ? allUnlocked
        : allUnlocked.where((type) {
      final def = buildingDefinitions[type];
      if (def == null) return false;

      // Very simple tag logic for now
      if (selectedFilter == 'Production' && def.baseProductionPerHour > 0) {
        return true;
      } else if (selectedFilter == 'Storage' && def.displayName.contains('Storage')) {
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

        return BuildingCard(
          type: type,
          level: level,
          definition: def,
          onUpgrade: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Upgrade "$type" coming soon!')),
            );
          },
        );
      },
    );
  }
}
