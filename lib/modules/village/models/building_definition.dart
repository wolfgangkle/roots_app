import 'dart:math';

/// 📚 Definition of each building for frontend use (display, preview costs, etc).
/// ⚠️ All calculations here are **client-side only** and must NOT be used for actual game logic.
class BuildingDefinition {
  final String type;
  final String displayName;
  final String description;
  final int maxLevel;
  final int baseProductionPerHour;
  final Map<String, int> baseCost;
  final UnlockCondition? unlockRequirement;

  // ⚙️ UI-only cost and time formulas for displaying preview values
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

  /// 💸 Returns estimated cost for display in UI only.
  Map<String, int> getCostForLevel(int level) {
    final multiplier = costMultiplierFormula?.call(level) ?? level;
    return baseCost.map((resource, base) => MapEntry(resource, base * multiplier));
  }

  /// ⏳ Returns estimated duration for display in UI only.
  Duration getBuildTime(int level) {
    return buildTimeFormula?.call(level) ??
        Duration(seconds: (30 * sqrt((level * level).toDouble())).round());
  }
}

/// 🔒 Optional unlock requirements for buildings.
/// Used in the UI to determine when buildings become visible/selectable.
class UnlockCondition {
  final String dependsOn;
  final int requiredLevel;

  UnlockCondition({
    required this.dependsOn,
    required this.requiredLevel,
  });
}
