import 'package:flutter/material.dart';
import 'package:roots_app/modules/village/models/building_definition.dart';
import 'package:roots_app/modules/village/widgets/upgrade_progress_indicator.dart';
import 'package:roots_app/modules/village/models/village_model.dart';
import 'package:roots_app/modules/village/extensions/village_model_extension.dart';

class BuildingCard extends StatelessWidget {
  final String type;
  final int level;
  final BuildingDefinition definition;
  final Widget? upgradeButtonWidget;
  final VillageModel village;

  const BuildingCard({
    super.key,
    required this.type,
    required this.level,
    required this.definition,
    required this.village,
    this.upgradeButtonWidget,
  });

  @override
  Widget build(BuildContext context) {
    final currentProduction = definition.baseProductionPerHour * level;
    final nextLevel = level + 1;
    final nextProduction = definition.baseProductionPerHour * nextLevel;
    final nextCost = definition.getCostForLevel(nextLevel);
    final nextDuration = definition.getBuildTime(nextLevel);
    final isUpgradingThis = village.currentBuildJob?.buildingType == type &&
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

          // 💸 Cost with red text for insufficient resources
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('💸 Costs: '),
              Expanded(child: _buildCostRichText(nextCost)),
            ],
          ),

          Text('⏱️ Takes: ${_formatDuration(nextDuration)}'),
          const SizedBox(height: 12),

          if (isUpgradingThis)
            UpgradeProgressIndicator(
              startedAt: village.currentBuildJob!.startedAt,
              endsAt: village.currentBuildJob!.startedAt
                  .add(village.currentBuildJob!.duration),
              villageId: village.id,
            )
          else if (upgradeButtonWidget != null)
            Align(
              alignment: Alignment.centerRight,
              child: upgradeButtonWidget!,
            )
          else
            Container(),
        ],
      ),
    );
  }

  /// 🔧 Builds a RichText with cost values in red if not affordable.
  Widget _buildCostRichText(Map<String, int> cost) {
    final simulated = village.simulatedResources;

    final spans = <TextSpan>[];
    cost.forEach((resource, amount) {
      final current = simulated[resource] ?? 0;
      final isEnough = current >= amount;

      spans.add(TextSpan(
        text: '$amount $resource',
        style: TextStyle(
          color: isEnough ? Colors.black : Colors.red,
          fontWeight: FontWeight.w500,
        ),
      ));

      spans.add(const TextSpan(text: ', ')); // comma separator
    });

    if (spans.isNotEmpty) {
      spans.removeLast(); // remove trailing comma
    }

    return RichText(
      text: TextSpan(style: const TextStyle(fontSize: 14), children: spans),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (minutes == 0) return '$seconds sec';
    return '$minutes min ${seconds.toString().padLeft(2, '0')} sec';
  }
}
