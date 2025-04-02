import '../models/building_definition.dart';

final buildingDefinitions = <String, BuildingDefinition>{
  'woodcutter': BuildingDefinition(
    type: 'woodcutter',
    displayName: 'Woodcutter',
    description: 'Produces wood over time.',
    maxLevel: 10,
    baseProductionPerHour: 100,
    costPerLevel: {
      'wood': 50,
      'stone': 20,
    },
  ),

  'quarry': BuildingDefinition(
    type: 'quarry',
    displayName: 'Quarry',
    description: 'Produces stone over time.',
    maxLevel: 10,
    baseProductionPerHour: 80,
    costPerLevel: {
      'wood': 60,
      'stone': 30,
    },
    unlockRequirement: UnlockCondition(
      dependsOn: 'woodcutter',
      requiredLevel: 1,
    ),
  ),

  'farm': BuildingDefinition(
    type: 'farm',
    displayName: 'Farm',
    description: 'Produces food over time.',
    maxLevel: 10,
    baseProductionPerHour: 120,
    costPerLevel: {
      'wood': 40,
      'stone': 40,
    },
    unlockRequirement: UnlockCondition(
      dependsOn: 'woodcutter',
      requiredLevel: 2,
    ),
  ),

  'mine': BuildingDefinition(
    type: 'mine',
    displayName: 'Iron Mine',
    description: 'Produces iron over time.',
    maxLevel: 10,
    baseProductionPerHour: 60,
    costPerLevel: {
      'wood': 80,
      'stone': 60,
    },
    unlockRequirement: UnlockCondition(
      dependsOn: 'quarry',
      requiredLevel: 2,
    ),
  ),

  'wood_storage': BuildingDefinition(
    type: 'wood_storage',
    displayName: 'Wood Storage',
    description: 'Increases your maximum wood capacity.',
    maxLevel: 5,
    baseProductionPerHour: 0, // not a production building
    costPerLevel: {
      'wood': 150,
      'stone': 100,
    },
    unlockRequirement: UnlockCondition(
      dependsOn: 'woodcutter',
      requiredLevel: 3,
    ),
  ),
};
