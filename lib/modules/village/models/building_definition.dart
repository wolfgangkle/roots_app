class BuildingDefinition {
  final String type;
  final String displayName;
  final String description;
  final int maxLevel;
  final int baseProductionPerHour;
  final Map<String, int> costPerLevel;
  final UnlockCondition? unlockRequirement;

  BuildingDefinition({
    required this.type,
    required this.displayName,
    required this.description,
    required this.maxLevel,
    required this.baseProductionPerHour,
    required this.costPerLevel,
    this.unlockRequirement,
  });
}

class UnlockCondition {
  final String dependsOn;
  final int requiredLevel;

  UnlockCondition({
    required this.dependsOn,
    required this.requiredLevel,
  });
}
