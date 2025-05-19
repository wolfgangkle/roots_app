final buildingDefinitions = [
  {
    "type": "hut",
    "displayName": {
      "default": "Hut",
    },
    "description": {
      "default": "A small hut to house your villagers.",
    },
    "baseCost": {
      "wood": 10,
      "stone": 3,
      "iron": 0,
      "gold": 0,
    },
    "costMultiplier": {
      "factor": 1.2,
      "linear": 0,
    },
    "baseBuildTimeSeconds": 300,
    "buildTimeScaling": {
      "factor": 1.1,
      "linear": 10,
    },
    "provides": {
      "workers": 6,
    },
    "raceNames": {
      "human": "Hut",
      "dwarf": "Shelter",
      "elf": "Leaf Shelter",
      "orc": "Mud Hut",
    },
  },
  {
    "type": "house",
    "displayName": {
      "default": "House",
    },
    "description": {
      "default": "A larger house to accommodate more villagers.",
    },
    "baseCost": {
      "wood": 80,
      "stone": 60,
      "iron": 10,
      "gold": 0,
    },
    "costMultiplier": {
      "factor": 1.3,
      "linear": 5,
    },
    "baseBuildTimeSeconds": 900,
    "buildTimeScaling": {
      "factor": 1.15,
      "linear": 20,
    },
    "provides": {
      "workers": 21,
    },
    "unlockRequirement": {
      "dependsOn": "hut",
      "requiredLevel": 12,
    },
    "raceNames": {
      "human": "House",
      "dwarf": "Stonehouse",
      "elf": "Treehouse",
      "orc": "War Hut",
    },
  },
];
