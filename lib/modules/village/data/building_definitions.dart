final buildingDefinitions = <Map<String, dynamic>>[
  {
    "type": "woodcutter",
    "displayName": "Woodcutter",
    "description": "Produces wood over time.",
    "maxLevel": 10,
    "baseProductionPerHour": 100,
    "baseCost": {
      "wood": 50,
      "stone": 20,
    },
    "unlockRequirement": null,
    "costMultiplier": {
      "formula": "linear",
      "base": 1,
      "factor": 1,
    },
    "buildTimeFormula": "default",
  },
  {
    "type": "quarry",
    "displayName": "Quarry",
    "description": "Produces stone over time.",
    "maxLevel": 10,
    "baseProductionPerHour": 80,
    "baseCost": {
      "wood": 60,
      "stone": 30,
    },
    "unlockRequirement": {
      "dependsOn": "woodcutter",
      "requiredLevel": 1,
    },
    "costMultiplier": {
      "formula": "linear",
      "base": 1,
      "factor": 1,
    },
    "buildTimeFormula": "default",
  },
  {
    "type": "farm",
    "displayName": "Farm",
    "description": "Produces food over time.",
    "maxLevel": 10,
    "baseProductionPerHour": 120,
    "baseCost": {
      "wood": 40,
      "stone": 40,
    },
    "unlockRequirement": {
      "dependsOn": "woodcutter",
      "requiredLevel": 2,
    },
    "costMultiplier": {
      "formula": "linear",
      "base": 1,
      "factor": 1,
    },
    "buildTimeFormula": "default",
  },
  {
    "type": "mine",
    "displayName": "Iron Mine",
    "description": "Produces iron over time.",
    "maxLevel": 10,
    "baseProductionPerHour": 60,
    "baseCost": {
      "wood": 80,
      "stone": 60,
    },
    "unlockRequirement": {
      "dependsOn": "quarry",
      "requiredLevel": 2,
    },
    "costMultiplier": {
      "formula": "linear",
      "base": 1,
      "factor": 1,
    },
    "buildTimeFormula": "default",
  },
  {
    "type": "wood_storage",
    "displayName": "Wood Storage",
    "description": "Increases your maximum wood capacity.",
    "maxLevel": 5,
    "baseProductionPerHour": 0,
    "baseCost": {
      "wood": 150,
      "stone": 100,
    },
    "unlockRequirement": {
      "dependsOn": "woodcutter",
      "requiredLevel": 3,
    },
    "costMultiplier": {
      "formula": "linear",
      "base": 1,
      "factor": 2, // Doubles each level (vs. 1x in producers)
    },
    "buildTimeFormula": "default",
  },
];
