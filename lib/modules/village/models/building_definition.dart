import 'dart:math';

class BuildingDefinition {
  final String type;
  final String displayName;
  final String description;
  final int maxLevel;
  final int baseProductionPerHour;
  final Map<String, int> baseCost;
  final UnlockCondition? unlockRequirement;

  // 🧮 Customizable formulas for cost and build time
  final int Function(int level)? costMultiplierFormula;
  final Duration Function(int level)? buildTimeFormula;

  BuildingDefinition({
    required this.type,
    required this.displayName,
    required this.description,
    required this.maxLevel,
    required this.baseProductionPerHour,
    required this.baseCost,
    this.unlockRequirement,
    this.costMultiplierFormula,
    this.buildTimeFormula,
  });

  /// 📦 Returns scaled cost for a given level using baseCost and formula
  Map<String, int> getCostForLevel(int level) {
    final multiplier = costMultiplierFormula?.call(level) ?? level;
    return baseCost.map((resource, base) => MapEntry(resource, base * multiplier));
  }

  /// ⏳ Returns build time for a given level using formula or default logic
  Duration getBuildTime(int level) {
    return buildTimeFormula?.call(level) ??
        Duration(seconds: (30 * sqrt((level * level).toDouble())).round());
  }
}

class UnlockCondition {
  final String dependsOn;
  final int requiredLevel;

  UnlockCondition({
    required this.dependsOn,
    required this.requiredLevel,
  });
}
