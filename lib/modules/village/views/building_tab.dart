import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:roots_app/modules/village/models/village_model.dart';
import 'package:roots_app/modules/village/data/building_definitions.dart';
import 'package:roots_app/modules/village/widgets/building_card.dart';
import 'package:roots_app/modules/village/extensions/village_model_extension.dart';
import 'package:roots_app/modules/village/widgets/upgrade_button.dart';

class BuildingTab extends StatefulWidget {
  final VillageModel village;
  final String selectedFilter;

  const BuildingTab({
    super.key,
    required this.village,
    required this.selectedFilter,
  });

  @override
  BuildingTabState createState() => BuildingTabState();
}

class BuildingTabState extends State<BuildingTab> {
  bool _globalUpgradeActive = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allUnlocked = widget.village.getUnlockedBuildings();
    final currentUpgrade = widget.village.currentBuildJob;
    final resources = widget.village.simulatedResources;

    final filteredDefinitions = buildingDefinitions.where((def) {
      final type = def['type'] as String?;
      if (type == null || !allUnlocked.contains(type)) return false;

      if (widget.selectedFilter == 'All') return true;

      final baseProduction = def['baseProductionPerHour'] as int? ?? 0;
      final displayNameMap = def['displayName'] as Map<String, dynamic>? ?? {};
      final displayName = displayNameMap['default']?.toString().toLowerCase() ?? '';

      if (widget.selectedFilter == 'Production') {
        return baseProduction > 0;
      } else if (widget.selectedFilter == 'Storage') {
        return displayName.contains('storage');
      }

      return false;
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredDefinitions.length,
      itemBuilder: (context, index) {
        final def = filteredDefinitions[index];
        final type = def['type'] as String;
        final level = widget.village.buildings[type]?.level ?? 0;
        final nextLevel = level + 1;

        final baseCost = Map<String, int>.from(def['baseCost'] as Map? ?? {});
        final costMultiplierMap = def['costMultiplier'] as Map<String, dynamic>? ?? {};
        final costFactor = costMultiplierMap['factor'] ?? 1;
        final costLinear = costMultiplierMap['linear'] ?? 0;

        final cost = baseCost.map((k, v) {
          final scaled = (v * pow(nextLevel, costFactor) + (nextLevel * costLinear)).round();
          return MapEntry(k, scaled);
        });

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
          village: widget.village,
          upgradeButtonWidget: canUpgrade
              ? UpgradeButton(
            buildingType: type,
            currentLevel: level,
            villageId: widget.village.id,
            isGloballyDisabled: _globalUpgradeActive,
            onGlobalUpgradeStart: () {
              setState(() => _globalUpgradeActive = true);
            },
            onUpgradeComplete: () {
              setState(() => _globalUpgradeActive = false);
            },
            onOptimisticUpgrade: () {
              widget.village.simulateUpgrade(type);
              setState(() {});
            },
          )
              : null,
        );
      },
    );
  }
}
