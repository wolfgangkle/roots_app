import '../models/building_definition.dart';

final buildingDefinitions = <String, BuildingDefinition>{
  'woodcutter': BuildingDefinition(
    type: 'woodcutter',
    displayName: 'Woodcutter',
    description: 'Produces wood over time.',
    maxLevel: 10,
    baseProductionPerHour: 100,
    baseCost: {
      'wood': 50,
      'stone': 20,
    },
    costMultiplierFormula: (level) => level,
    buildTimeFormula: (level) => Duration(seconds: 20 + level * 10),
  ),

  'quarry': BuildingDefinition(
    type: 'quarry',
    displayName: 'Quarry',
    description: 'Produces stone over time.',
    maxLevel: 10,
    baseProductionPerHour: 80,
    baseCost: {
      'wood': 60,
      'stone': 30,
    },
    unlockRequirement: UnlockCondition(
      dependsOn: 'woodcutter',
      requiredLevel: 1,
    ),
    costMultiplierFormula: (level) => level,
    buildTimeFormula: (level) => Duration(seconds: 25 + level * 12),
  ),

  'farm': BuildingDefinition(
    type: 'farm',
    displayName: 'Farm',
    description: 'Produces food over time.',
    maxLevel: 10,
    baseProductionPerHour: 120,
    baseCost: {
      'wood': 40,
      'stone': 40,
    },
    unlockRequirement: UnlockCondition(
      dependsOn: 'woodcutter',
      requiredLevel: 2,
    ),
    costMultiplierFormula: (level) => level,
    buildTimeFormula: (level) => Duration(seconds: 22 + level * 11),
  ),

  'mine': BuildingDefinition(
    type: 'mine',
    displayName: 'Iron Mine',
    description: 'Produces iron over time.',
    maxLevel: 10,
    baseProductionPerHour: 60,
    baseCost: {
      'wood': 80,
      'stone': 60,
    },
    unlockRequirement: UnlockCondition(
      dependsOn: 'quarry',
      requiredLevel: 2,
    ),
    costMultiplierFormula: (level) => level,
    buildTimeFormula: (level) => Duration(seconds: 30 + level * 14),
  ),

  'wood_storage': BuildingDefinition(
    type: 'wood_storage',
    displayName: 'Wood Storage',
    description: 'Increases your maximum wood capacity.',
    maxLevel: 5,
    baseProductionPerHour: 0, // Not a production building
    baseCost: {
      'wood': 150,
      'stone': 100,
    },
    unlockRequirement: UnlockCondition(
      dependsOn: 'woodcutter',
      requiredLevel: 3,
    ),
    costMultiplierFormula: (level) => level + 1,
    buildTimeFormula: (level) => Duration(seconds: 40 + level * 20),
  ),
};
