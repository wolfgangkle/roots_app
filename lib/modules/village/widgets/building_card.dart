import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:roots_app/modules/village/widgets/upgrade_progress_indicator.dart';
import 'package:roots_app/modules/village/models/village_model.dart';
import 'package:roots_app/modules/village/extensions/village_model_extension.dart';

// 🔷 Tokens
import 'package:roots_app/theme/app_style_manager.dart';
import 'package:roots_app/theme/widgets/token_panels.dart';
import 'package:roots_app/theme/tokens.dart';

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
    // 🔄 Live tokens
    context.watch<StyleManager>();
    final GlassTokens glass = kStyle.glass;
    final TextOnGlassTokens text = kStyle.textOnGlass;
    final EdgeInsets cardPad = kStyle.card.padding;

    final int baseProduction = definition['baseProductionPerHour'] as int? ?? 0;
    final Map<String, dynamic> displayNameMap =
        definition['displayName'] as Map<String, dynamic>? ?? {};
    final String name = (displayNameMap['default'] ?? 'Unknown').toString();

    final Map<String, int> baseCost =
    Map<String, int>.from(definition['baseCost'] ?? {});
    final Map<String, dynamic> costMultiplier =
        definition['costMultiplier'] as Map<String, dynamic>? ?? {};
    final num costFactor = (costMultiplier['factor'] as num?) ?? 1.0;
    final num costLinear = (costMultiplier['linear'] as num?) ?? 0;

    final int currentProduction = baseProduction * level;
    final int nextLevel = level + 1;
    final int nextProduction = baseProduction * nextLevel;

    final Map<String, int> nextCost = baseCost.map((k, v) {
      final num linearPart = k == 'gold' ? 0 : nextLevel * costLinear;
      final int scaled = (v * pow(nextLevel, costFactor) + linearPart).round();
      return MapEntry(k, scaled);
    });

    final Map<String, dynamic> buildTimeScaling =
        definition['buildTimeScaling'] as Map<String, dynamic>? ?? {};
    final int baseBuildTime = definition['baseBuildTimeSeconds'] as int? ?? 30;
    final num timeFactor = (buildTimeScaling['factor'] as num?) ?? 1.0;
    final num timeLinear = (buildTimeScaling['linear'] as num?) ?? 0;

    final int seconds =
    (baseBuildTime * pow(nextLevel, timeFactor) + (nextLevel * timeLinear))
        .round();
    final Duration nextDuration = Duration(seconds: seconds);

    final bool isUpgradingThis =
        village.currentBuildJob?.buildingType == type &&
            village.currentBuildJob?.isComplete == false;

    return TokenPanel(
      glass: glass,
      text: text,
      padding: EdgeInsets.fromLTRB(cardPad.left, 12, cardPad.right, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🏷 Title
          Text(
            '$name (Level $level)',
            style: TextStyle(
              color: text.primary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),

          // 📦 Current production
          if (baseProduction > 0)
            Text(
              '📦 Produces: $currentProduction per hour',
              style: TextStyle(color: text.secondary),
            ),

          const SizedBox(height: 12),
          // Subheader
          Text(
            '➡️ Next Level ($nextLevel):',
            style: TextStyle(color: text.primary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),

          if (baseProduction > 0)
            Text(
              '📦 Produces: $nextProduction per hour',
              style: TextStyle(color: text.secondary),
            ),

          // 💸 Costs
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('💸 Costs: ', style: TextStyle(color: text.secondary)),
              Expanded(child: _buildCostRichText(context, nextCost, text)),
            ],
          ),

          // ⏱ Duration
          const SizedBox(height: 4),
          Text(
            '⏱️ Takes: ${_formatDuration(nextDuration)}',
            style: TextStyle(color: text.secondary),
          ),

          const SizedBox(height: 12),

          // ▶️ Action / progress
          if (isUpgradingThis)
            UpgradeProgressIndicator(
              startedAt: village.currentBuildJob!.startedAt,
              endsAt:
              village.currentBuildJob!.startedAt.add(village.currentBuildJob!.duration),
              villageId: village.id,
            )
          else if (upgradeButtonWidget != null)
            Align(
              alignment: Alignment.centerRight,
              child: upgradeButtonWidget!,
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildCostRichText(
      BuildContext context,
      Map<String, int> cost,
      TextOnGlassTokens text,
      ) {
    final simulated = village.simulatedResources;
    final Color danger = Theme.of(context).colorScheme.error;

    final spans = <TextSpan>[];
    cost.forEach((resource, amount) {
      final int current = simulated[resource] ?? 0;
      final bool isEnough = current >= amount;

      spans.add(TextSpan(
        text: '$amount $resource',
        style: TextStyle(
          color: isEnough ? text.primary : danger,
          fontWeight: FontWeight.w500,
        ),
      ));
      spans.add(TextSpan(
        text: ', ',
        style: TextStyle(color: text.subtle),
      ));
    });

    if (spans.isNotEmpty) spans.removeLast();

    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 14),
        children: spans,
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (minutes == 0) return '$seconds sec';
    return '$minutes min ${seconds.toString().padLeft(2, '0')} sec';
  }
}
