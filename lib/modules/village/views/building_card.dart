import 'package:flutter/material.dart';
import 'package:roots_app/modules/village/models/building_definition.dart';
import 'package:roots_app/modules/village/widgets/upgrade_button.dart';
import 'package:roots_app/modules/village/widgets/upgrade_progress_indicator.dart';
import 'package:roots_app/modules/village/models/village_model.dart';

class BuildingCard extends StatelessWidget {
  final String type;
  final int level;
  final BuildingDefinition definition;
  final Widget? upgradeButtonWidget; // New optional widget parameter
  final VillageModel village;

  const BuildingCard({
    Key? key,
    required this.type,
    required this.level,
    required this.definition,
    required this.village,
    this.upgradeButtonWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentProduction = definition.baseProductionPerHour * level;
    final nextLevel = level + 1;
    final nextProduction = definition.baseProductionPerHour * nextLevel;
    final nextCost = definition.getCostForLevel(nextLevel);
    final nextDuration = definition.getBuildTime(nextLevel);
    final isUpgradingThis =
        village.currentBuildJob?.buildingType == type &&
            village.currentBuildJob?.isComplete == false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🏗️ Name + Level
          Text(
            '${definition.displayName} (Level $level)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // 📦 Current production
          if (definition.baseProductionPerHour > 0)
            Text('📦 Produces: $currentProduction per hour'),

          // ➡️ Next level info
          const Divider(height: 20),
          Text('➡️ Next Level ($nextLevel):'),
          if (definition.baseProductionPerHour > 0)
            Text('📦 Produces: $nextProduction per hour'),
          Text('💸 Costs: ${_formatCost(nextCost)}'),
          Text('⏱️ Takes: ${_formatDuration(nextDuration)}'),
          const SizedBox(height: 12),

          // 🔄 Either show the upgrade progress indicator or the upgrade button widget.
          if (isUpgradingThis)
            UpgradeProgressIndicator(
              startedAt: village.currentBuildJob!.startedAt,
              endsAt: village.currentBuildJob!.startedAt
                  .add(village.currentBuildJob!.duration),
              villageId: village.id, // Pass the village ID if needed inside the indicator.
            )
          else if (upgradeButtonWidget != null)
            Align(
              alignment: Alignment.centerRight,
              child: upgradeButtonWidget!,
            )
          else
            Container(), // Fallback: empty container.
        ],
      ),
    );
  }

  String _formatCost(Map<String, int> cost) {
    return cost.entries.map((e) => '${e.value} ${e.key}').join(', ');
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (minutes == 0) return '$seconds sec';
    return '$minutes min ${seconds.toString().padLeft(2, '0')} sec';
  }
}
