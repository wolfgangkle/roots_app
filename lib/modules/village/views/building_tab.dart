import 'dart:async';
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
    Key? key,
    required this.village,
    required this.selectedFilter,
  }) : super(key: key);

  @override
  _BuildingTabState createState() => _BuildingTabState();
}

class _BuildingTabState extends State<BuildingTab> {
  bool _globalUpgradeActive = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
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

    final filtered = widget.selectedFilter == 'All'
        ? allUnlocked
        : allUnlocked.where((type) {
      final def = buildingDefinitions[type];
      if (def == null) return false;
      if (widget.selectedFilter == 'Production' &&
          def.baseProductionPerHour > 0) {
        return true;
      } else if (widget.selectedFilter == 'Storage' &&
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
        final level = widget.village.buildings[type]?.level ?? 0;
        final nextLevel = level + 1;

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
          village: widget.village,
          upgradeButtonWidget: canUpgrade
              ? UpgradeButton(
            buildingType: type,
            currentLevel: level,
            villageId: widget.village.id,
            isGloballyDisabled: _globalUpgradeActive,
            onGlobalUpgradeStart: () {
              setState(() {
                _globalUpgradeActive = true;
              });
            },
            onUpgradeComplete: () {
              setState(() {
                _globalUpgradeActive = false;
              });
            },
            /// 💥 Optimistic update: instantly simulate building progress
            onOptimisticUpgrade: () {
              widget.village.simulateUpgrade(type); // You'll implement this
              setState(() {});
            },
          )
              : null,
        );
      },
    );
  }
}
