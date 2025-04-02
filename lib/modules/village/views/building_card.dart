import 'package:flutter/material.dart';
import 'package:roots_app/modules/village/models/building_definition.dart';
import 'package:roots_app/modules/village/data/building_definitions.dart';


class BuildingCard extends StatelessWidget {
  final String type;
  final int level;
  final BuildingDefinition definition;
  final VoidCallback onUpgrade;

  const BuildingCard({
    super.key,
    required this.type,
    required this.level,
    required this.definition,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final production = definition.baseProductionPerHour * level;
    final upgradeCost = definition.costPerLevel;

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
            Text('💸 Upgrade cost: ${_formatCost(upgradeCost)}'),
          ],

          // 🧱 Requirements
          if (definition.unlockRequirement != null) ...[
            const SizedBox(height: 4),
            Text(
              '🧱 Requires: ${definition.unlockRequirement!.dependsOn} Level ${definition.unlockRequirement!.requiredLevel}',
              style: const TextStyle(color: Colors.grey),
            ),
          ],

          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: onUpgrade,
                child: const Text('Upgrade'),
              ),
            ],
          )
        ],
      ),
    );
  }

  String _formatCost(Map<String, int> cost) {
    return cost.entries.map((e) => '${e.value} ${e.key}').join(', ');
  }
}
