import 'package:flutter/material.dart';
import 'package:roots_app/modules/village/models/building_definition.dart';
import 'package:roots_app/modules/village/widgets/upgrade_button.dart';
import 'package:roots_app/modules/village/widgets/upgrade_progress_indicator.dart';
import 'package:roots_app/modules/village/models/village_model.dart';

class BuildingCard extends StatelessWidget {
  final String type;
  final int level;
  final BuildingDefinition definition;
  final VoidCallback? onUpgrade;
  final VillageModel village;

  const BuildingCard({
    super.key,
    required this.type,
    required this.level,
    required this.definition,
    required this.onUpgrade,
    required this.village,
  });

  @override
  Widget build(BuildContext context) {
    final production = definition.baseProductionPerHour * level;
    final nextLevel = level + 1;
    final upgradeCost = definition.getCostForLevel(nextLevel);
    final upgradeTime = definition.getBuildTime(nextLevel);
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

          // ⚙️ Production
          if (definition.baseProductionPerHour > 0)
            Text('📦 Produces: $production per hour'),

          // 💸 Upgrade Cost
          if (upgradeCost.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('💸 Next upgrade cost: ${_formatCost(upgradeCost)}'),
          ],

          // ⏱️ Upgrade time
          const SizedBox(height: 4),
          Text('⏱️ Takes: ${_formatDuration(upgradeTime)}'),

          const SizedBox(height: 12),

          // 🔄 Show progress bar or upgrade button
          if (isUpgradingThis)
            UpgradeProgressIndicator(
              startedAt: village.currentBuildJob!.startedAt,
              endsAt: village.currentBuildJob!.startedAt.add(
                village.currentBuildJob!.duration,
              ),
            )
          else
            Align(
              alignment: Alignment.centerRight,
              child: UpgradeButton(
                buildingType: type,
                currentLevel: level,
                onUpgradeQueued: onUpgrade,
              ),
            ),
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
