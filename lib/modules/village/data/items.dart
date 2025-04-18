final gameItems = <String, Map<String, dynamic>>{
  // 🪵 BASE ITEMS (always available)
  "wooden_stick": {
    "name": "Wooden Stick",
    "type": "weapon",
    "subType": "club",
    "equipSlot": "main_hand",
    "buildTime": 600,
    "craftingCost": { "wood": 60 },
    "baseStats": {
      "damage": 4,
      "attackSpeed": 900,
      "balance": 1,
      "weight": 1
    },
    "description": "A rough branch. Better than nothing.",
  },
  "wooden_club": {
    "name": "Wooden Club",
    "type": "weapon",
    "subType": "club",
    "equipSlot": "main_hand",
    "buildTime": 900,
    "craftingCost": { "wood": 90 },
    "baseStats": {
      "damage": 6,
      "attackSpeed": 1100,
      "balance": 1,
      "weight": 2
    },
    "description": "Heavy but slow. A basic smashing tool.",
  },
  "cloth_robe": {
    "name": "Basic Cloth Robe",
    "type": "armor",
    "subType": "chest",
    "equipSlot": "chest",
    "buildTime": 900,
    "craftingCost": { "wood": 80 },
    "baseStats": {
      "armor": 1,
      "camouflage": 2,
      "weight": 1
    },
    "description": "Woven from scraps. Barely protective.",
  },

  // 🛠️ FORGE LEVEL 1
  "wooden_sword": {
    "name": "Wooden Sword",
    "type": "weapon",
    "subType": "sword",
    "equipSlot": "main_hand",
    "buildTime": 1200,
    "craftingCost": { "wood": 180 },
    "baseStats": {
      "damage": 7,
      "attackSpeed": 800,
      "balance": 2,
      "weight": 1
    },
    "description": "A carved blade made from hardwood.",
    "unlockRequirement": { "building": "forge", "level": 1 },
  },
  "rusty_dagger": {
    "name": "Rusty Dagger",
    "type": "weapon",
    "subType": "dagger",
    "equipSlot": "main_hand",
    "buildTime": 1500,
    "craftingCost": { "wood": 100, "stone": 100 },
    "baseStats": {
      "damage": 5,
      "attackSpeed": 600,
      "balance": 3,
      "weight": 1
    },
    "description": "Corroded but quick. Keep it away from flesh wounds.",
    "unlockRequirement": { "building": "forge", "level": 1 },
  },
  "wooden_shield": {
    "name": "Wooden Shield",
    "type": "armor",
    "subType": "shield",
    "equipSlot": "offhand",
    "buildTime": 1800,
    "craftingCost": { "wood": 250 },
    "baseStats": {
      "armor": 3,
      "camouflage": 0,
      "weight": 2
    },
    "description": "Crude defense. Blocks some damage.",
    "unlockRequirement": { "building": "forge", "level": 1 },
  },

  // 🧤 FORGE LEVEL 3 – LEATHER ARMOR SET
  "leather_helmet": {
    "name": "Leather Helmet",
    "type": "armor",
    "subType": "helmet",
    "equipSlot": "head",
    "buildTime": 3600,
    "craftingCost": { "wood": 150, "iron": 100 },
    "baseStats": {
      "armor": 2,
      "camouflage": 1,
      "weight": 1
    },
    "description": "Soft helmet offering light protection.",
    "unlockRequirement": { "building": "forge", "level": 3 },
  },
  "leather_chest": {
    "name": "Leather Chestplate",
    "type": "armor",
    "subType": "chest",
    "equipSlot": "chest",
    "buildTime": 4800,
    "craftingCost": { "wood": 200, "iron": 150 },
    "baseStats": {
      "armor": 6,
      "camouflage": 2,
      "weight": 2
    },
    "description": "Flexible leather armor for the torso.",
    "unlockRequirement": { "building": "forge", "level": 3 },
  },
  "leather_gloves": {
    "name": "Leather Gloves",
    "type": "armor",
    "subType": "gloves",
    "equipSlot": "hands",
    "buildTime": 3600,
    "craftingCost": { "wood": 120, "iron": 80 },
    "baseStats": {
      "armor": 2,
      "camouflage": 1,
      "weight": 1
    },
    "description": "Soft gloves, good for grip and stealth.",
    "unlockRequirement": { "building": "forge", "level": 3 },
  },
  "leather_belt": {
    "name": "Leather Belt",
    "type": "armor",
    "subType": "belt",
    "equipSlot": "belt",
    "buildTime": 3600,
    "craftingCost": { "wood": 100, "iron": 60 },
    "baseStats": {
      "armor": 1,
      "camouflage": 1,
      "weight": 1
    },
    "description": "A sturdy leather strap. Helps tie the outfit together.",
    "unlockRequirement": { "building": "forge", "level": 3 },
  },
    "leather_pants": {
    "name": "Leather Pants",
    "type": "armor",
    "subType": "legs",
    "equipSlot": "legs",
    "buildTime": 4800,
    "craftingCost": { "wood": 180, "iron": 120 },
    "baseStats": {
      "armor": 4,
      "camouflage": 1,
      "weight": 2
    },
    "description": "Mobility-friendly leather trousers.",
    "unlockRequirement": { "building": "forge", "level": 3 },
  },
  "leather_boots": {
    "name": "Leather Boots",
    "type": "armor",
    "subType": "boots",
    "equipSlot": "feet",
    "buildTime": 3600,
    "craftingCost": { "wood": 120, "iron": 80 },
    "baseStats": {
      "armor": 2,
      "camouflage": 1,
      "weight": 1
    },
    "description": "Quiet footsteps, minimal protection.",
    "unlockRequirement": { "building": "forge", "level": 3 },
  },

  // 🗡️ FORGE LEVEL 5 – IRON TIER
  "iron_sword": {
    "name": "Iron Sword",
    "type": "weapon",
    "subType": "sword",
    "equipSlot": "main_hand",
    "buildTime": 7200,
    "craftingCost": { "iron": 500, "wood": 100 },
    "baseStats": {
      "damage": 15,
      "attackSpeed": 750,
      "balance": 3,
      "weight": 2
    },
    "description": "A standard issue sword forged from iron.",
    "unlockRequirement": { "building": "forge", "level": 5 },
  },
  "iron_axe": {
    "name": "Iron Axe",
    "type": "weapon",
    "subType": "axe",
    "equipSlot": "main_hand",
    "buildTime": 7800,
    "craftingCost": { "iron": 600, "wood": 150 },
    "baseStats": {
      "damage": 18,
      "attackSpeed": 850,
      "balance": 2,
      "weight": 3
    },
    "description": "Heavy and brutal. Not for finesse fighters.",
    "unlockRequirement": { "building": "forge", "level": 5 },
  },
  "iron_mace": {
    "name": "Iron Mace",
    "type": "weapon",
    "subType": "mace",
    "equipSlot": "main_hand",
    "buildTime": 7800,
    "craftingCost": { "iron": 550, "wood": 130 },
    "baseStats": {
      "damage": 20,
      "attackSpeed": 1000,
      "balance": 1,
      "weight": 4
    },
    "description": "A heavy iron club to break bones and shields.",
    "unlockRequirement": { "building": "forge", "level": 5 },
  },
  "iron_battle_axe": {
    "name": "Iron Battle Axe",
    "type": "weapon",
    "subType": "axe",
    "equipSlot": "two_hand",
    "buildTime": 10800,
    "craftingCost": { "iron": 1000, "wood": 200 },
    "baseStats": {
      "damage": 30,
      "attackSpeed": 1200,
      "balance": 1,
      "weight": 6
    },
    "description": "Two-handed terror. Slow but devastating.",
    "unlockRequirement": { "building": "forge", "level": 5 },
  },
  "iron_shield": {
    "name": "Iron Shield",
    "type": "armor",
    "subType": "shield",
    "equipSlot": "offhand",
    "buildTime": 7200,
    "craftingCost": { "iron": 600, "wood": 150 },
    "baseStats": {
      "armor": 6,
      "camouflage": -1,
      "weight": 3
    },
    "description": "A sturdy shield forged to absorb punishment.",
    "unlockRequirement": { "building": "forge", "level": 5 },
  },

  "iron_belt": {
    "name": "Iron Belt",
    "type": "armor",
    "subType": "belt",
    "equipSlot": "belt",
    "buildTime": 7200,
    "craftingCost": { "iron": 400, "wood": 100 },
    "baseStats": {
      "armor": 2,
      "camouflage": -1,
      "weight": 2
    },
    "description": "Forged from thick plates. Keeps your stance solid.",
    "unlockRequirement": { "building": "forge", "level": 5 },
  },
  "iron_helmet": {
    "name": "Iron Helmet",
    "type": "armor",
    "subType": "helmet",
    "equipSlot": "head",
    "buildTime": 7200,
    "craftingCost": { "iron": 500, "wood": 100 },
    "baseStats": {
      "armor": 4,
      "camouflage": -1,
      "weight": 2
    },
    "description": "Protects your noggin with thick iron plating.",
    "unlockRequirement": { "building": "forge", "level": 5 },
  },

  "iron_chestplate": {
    "name": "Iron Chestplate",
    "type": "armor",
    "subType": "chest",
    "equipSlot": "chest",
    "buildTime": 9000,
    "craftingCost": { "iron": 700, "wood": 150 },
    "baseStats": {
      "armor": 10,
      "camouflage": -2,
      "weight": 4
    },
    "description": "Heavy and solid. Absorbs brutal blows.",
    "unlockRequirement": { "building": "forge", "level": 5 },
  },

  "iron_gauntlets": {
    "name": "Iron Gauntlets",
    "type": "armor",
    "subType": "gloves",
    "equipSlot": "hands",
    "buildTime": 7200,
    "craftingCost": { "iron": 400, "wood": 80 },
    "baseStats": {
      "armor": 3,
      "camouflage": -1,
      "weight": 2
    },
    "description": "Clunky but protective handguards.",
    "unlockRequirement": { "building": "forge", "level": 5 },
  },

  "iron_greaves": {
    "name": "Iron Greaves",
    "type": "armor",
    "subType": "legs",
    "equipSlot": "legs",
    "buildTime": 9000,
    "craftingCost": { "iron": 650, "wood": 120 },
    "baseStats": {
      "armor": 6,
      "camouflage": -1,
      "weight": 3
    },
    "description": "Thick armor for strong legs.",
    "unlockRequirement": { "building": "forge", "level": 5 },
  },

  "iron_boots": {
    "name": "Iron Boots",
    "type": "armor",
    "subType": "boots",
    "equipSlot": "feet",
    "buildTime": 7200,
    "craftingCost": { "iron": 350, "wood": 100 },
    "baseStats": {
      "armor": 3,
      "camouflage": -1,
      "weight": 2
    },
    "description": "Clank, clank. Built for stomping.",
    "unlockRequirement": { "building": "forge", "level": 5 },
  },
};

