import 'dart:math';
import 'package:flutter/material.dart';
import 'package:roots_app/modules/village/widgets/upgrade_progress_indicator.dart';
import 'package:roots_app/modules/village/models/village_model.dart';
import 'package:roots_app/modules/village/extensions/village_model_extension.dart';

class BuildingCard extends StatelessWidget {
  final String type;
  final int level;
  final Map<String, dynamic> definition;
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
    final baseProduction = (definition['baseProductionPerHour'] ?? 0) as int;
    final displayNameMap = definition['displayName'] as Map<String, dynamic>? ?? {};
    final name = displayNameMap['default'] ?? 'Unknown';

    final baseCost = Map<String, int>.from(definition['baseCost'] ?? {});
    final costMultiplier = definition['costMultiplier'] as Map<String, dynamic>? ?? {};
    final costFactor = costMultiplier['factor'] ?? 1.0;
    final costLinear = costMultiplier['linear'] ?? 0;

    final currentProduction = baseProduction * level;
    final nextLevel = level + 1;
    final nextProduction = baseProduction * nextLevel;

    final nextCost = baseCost.map((k, v) {
      final scaled = (v * pow(nextLevel, costFactor) + (nextLevel * costLinear)).round();
      return MapEntry(k, scaled);
    });

    final buildTimeScaling = definition['buildTimeScaling'] as Map<String, dynamic>? ?? {};
    final baseBuildTime = definition['baseBuildTimeSeconds'] as int? ?? 30;
    final timeFactor = buildTimeScaling['factor'] ?? 1.0;
    final timeLinear = buildTimeScaling['linear'] ?? 0;

    final seconds = (baseBuildTime * pow(nextLevel, timeFactor) + (nextLevel * timeLinear)).round();
    final nextDuration = Duration(seconds: seconds);

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
          Text(
            '$name (Level $level)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          if (baseProduction > 0)
            Text('📦 Produces: $currentProduction per hour'),

          const Divider(height: 20),
          Text('➡️ Next Level ($nextLevel):'),

          if (baseProduction > 0)
            Text('📦 Produces: $nextProduction per hour'),

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

      spans.add(const TextSpan(text: ', '));
    });

    if (spans.isNotEmpty) spans.removeLast();

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
