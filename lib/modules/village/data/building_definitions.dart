final buildingDefinitions = [

  // === HUT BRANCH ===

  {
    "type": "hut",
    "displayName": {"default": "Hut"},
    "description": {
      "default": "A small hut to house your villagers."
    },
    "baseCost": {"wood": 10, "stone": 3, "iron": 0, "gold": 0},
    "costMultiplier": {"factor": 1.2, "linear": 0},
    "baseBuildTimeSeconds": 300,
    "buildTimeScaling": {"factor": 1.1, "linear": 10},
    "provides": {"workers": 6},
    "points": 2,
    "raceNames": {
      "human": "Hut",
      "dwarf": "Shelter",
      "elf": "Leaf Shelter",
      "orc": "Mud Hut",
    },
  },

  {
    "type": "lookout_post",
    "displayName": {"default": "Lookout Post"},
    "description": {
      "default": "A simple elevated platform for spotting enemies early. Boosts village defense visibility and offers limited protection during raids."
    },
    "baseCost": {"wood": 30, "stone": 10, "iron": 0, "gold": 0},
    "costMultiplier": {"factor": 1.2, "linear": 2},
    "baseBuildTimeSeconds": 400,
    "buildTimeScaling": {"factor": 1.1, "linear": 20},
    "unlockRequirement": {
      "dependsOn": "hut",
      "requiredLevel": 2,
    },
    "provides": {
      "combatStats": {
        "spy": 3,
        "hp": 5,
        "attack": 15,
        "defense": 5,
        "damage": 3,
        "attackSpeed": 180000, // in milliseconds
        "expOnDestroyed": 1
      }
    },
    "points": 4,
    "raceNames": {
      "human": "Lookout Post",
      "dwarf": "Observation Tower",
      "elf": "Leaf Lookout",
      "orc": "Spear Post",
    },
  },



  {
    "type": "camouflage_wall",
    "displayName": {"default": "Camouflage Wall"},
    "description": {
      "default": "Lightly concealed perimeter that hides your village layout and weakens scouting."
    },
    "baseCost": {"wood": 50, "stone": 20, "iron": 0, "gold": 0},
    "costMultiplier": {"factor": 1.2, "linear": 3},
    "baseBuildTimeSeconds": 500,
    "buildTimeScaling": {"factor": 1.1, "linear": 25},
    "unlockRequirement": {
      "dependsOn": "lookout_post",
      "requiredLevel": 1,
    },
    "provides": {
      "camouflage": 3
    }
    "points": 5,
    "raceNames": {
      "human": "Camouflage Wall",
      "dwarf": "Hidden Ridge",
      "elf": "Vine Fence",
      "orc": "Bone Scramble",
    },
  },

  {
    "type": "quarry",
    "displayName": {
      "default": "Quarry"
    },
    "description": {
      "default": "Sturdy workers extract stone from the quarry to support your construction efforts. Stone is essential for fortifications and workshops alike."
    },
    "baseCost": {
      "wood": 7,
      "stone": 0,
      "iron": 20,
      "gold": 0
    },
    "costMultiplier": {
      "factor": 1.2,
      "linear": 2
    },
    "baseBuildTimeSeconds": 300,
    "buildTimeScaling": {
      "factor": 1.1,
      "linear": 15
    },
    "workerPerLevel": 2,
    "provides": {
      "workers": 1,
      "maxProductionPerHour": {
        "stone": 80
      },
      "maxSecuredResources": {
        "stone": 10
      }
    },
    "unlockRequirement": {
      "dependsOn": "hut",
      "requiredLevel": 3
    },
    "points": 6,
    "raceNames": {
      "human": "Quarry",
      "dwarf": "Stone Pit",
      "elf": "Rock Grove",
      "orc": "Cracker Hole"
    }
  }

  {
    "type": "stone_storage",
    "displayName": {"default": "Stone Storage"},
    "description": {
      "default": "Reinforced pits and stone warehouses prevent your quarry yield from crumbling away. Store enough stone to build and fortify your settlement against threats."
    },
    "baseCost": {"wood": 30, "stone": 40, "iron": 5, "gold": 0},
    "costMultiplier": {"factor": 1.2, "linear": 4},
    "baseBuildTimeSeconds": 300,
    "buildTimeScaling": {"factor": 1.1, "linear": 15},
    "provides": {"storageCapacity": {"stone": 1000}},
    "unlockRequirement": {
      "dependsOn": "quarry",
      "requiredLevel": 3,
    },
    "points": 4,
    "raceNames": {
      "human": "Stone Depot",
      "dwarf": "Rock Vault",
      "elf": "Stone Grove",
      "orc": "Pebble Pit",
    },
  },

  {
    "type": "stone_bunker",
    "displayName": {"default": "Stone Bunker"},
    "description": {
      "default": "Caverns and reinforced vaults shield your precious stone from prying hands. Even the boldest raiders will struggle to carry it off."
    },
    "baseCost": {"wood": 40, "stone": 50, "iron": 5, "gold": 0},
    "costMultiplier": {"factor": 1.2, "linear": 3},
    "baseBuildTimeSeconds": 400,
    "buildTimeScaling": {"factor": 1.1, "linear": 20},
    "provides": {"maxSecuredResources": {"stone": 300}},
    "unlockRequirement": {
      "dependsOn": "stone_storage",
      "requiredLevel": 4,
    },
    "points": 5,
    "raceNames": {
      "human": "Stone Bunker",
      "dwarf": "Buried Cache",
      "elf": "Grove Vault",
      "orc": "Rock Pile",
    },
  },

  {
    "type": "palisade",
    "displayName": {"default": "Palisade"},
    "description": {
      "default": "A rough wooden wall offering basic protection against enemy raids. The first line of defense for any serious village."
    },
    "baseCost": {"wood": 100, "stone": 50, "iron": 0, "gold": 0},
    "costMultiplier": {"factor": 1.25, "linear": 8},
    "baseBuildTimeSeconds": 800,
    "buildTimeScaling": {"factor": 1.15, "linear": 30},
    "unlockRequirement": {
      "dependsOn": "quarry",
      "requiredLevel": 21,
    },
    "provides": {
      "combatStats": {
        "wallHp": 5
      }
    },
    "points": 8,
    "raceNames": {
      "human": "Palisade",
      "dwarf": "Stone Barricade",
      "elf": "Thorn Barrier",
      "orc": "Spiked Fence",
    },
  },


  {
    "type": "academy_of_arts",
    "displayName": {"default": "Academy of Arts"},
    "description": {
      "default": "A mystical place where spells are researched and improved. The center of magical advancement."
    },
    "baseCost": {"wood": 60, "stone": 60, "iron": 20, "gold": 10},
    "costMultiplier": {"factor": 1.3, "linear": 5},
    "baseBuildTimeSeconds": 600,
    "buildTimeScaling": {"factor": 1.15, "linear": 30},
    "unlockRequirement": {
      "dependsOn": "hut",
      "requiredLevel": 3,
    },
    "points": 10,
    "raceNames": {
      "human": "Academy of Arts",
      "dwarf": "Runestone Hall",
      "elf": "Moonshade Enclave",
      "orc": "Skull Shrine",
    },
  },

  {
    "type": "trade_cart",
    "displayName": {"default": "Trade Cart"},
    "description": {
      "default":
      "A sturdy cart to carry goods between villages. Each level increases your daily trade capacity with other villages."
    },
    "baseCost": {"wood": 80, "stone": 50, "iron": 20, "gold": 0},
    "costMultiplier": {"factor": 1.2, "linear": 6},
    "baseBuildTimeSeconds": 700,
    "buildTimeScaling": {"factor": 1.1, "linear": 25},
    "provides": {
      "maxDailyTradeAmount": 5000
    },
    "unlockRequirement": {
      "dependsOn": "hut",
      "requiredLevel": 5,
    },
    "points": 6,
    "raceNames": {
      "human": "Trade Cart",
      "dwarf": "Ore Wagon",
      "elf": "Glade Runner",
      "orc": "Loot Cart",
    },
  },


  {
    "type": "house",
    "displayName": {"default": "House"},
    "description": {"default": "A larger house to accommodate more villagers."},
    "baseCost": {"wood": 80, "stone": 60, "iron": 10, "gold": 0},
    "costMultiplier": {"factor": 1.3, "linear": 5},
    "baseBuildTimeSeconds": 900,
    "buildTimeScaling": {"factor": 1.15, "linear": 20},
    "provides": {"workers": 21},
    "unlockRequirement": {
      "dependsOn": "hut",
      "requiredLevel": 12,
    },
    "points": 10,
    "raceNames": {
      "human": "House",
      "dwarf": "Stonehouse",
      "elf": "Treehouse",
      "orc": "War Hut",
    },
  },

  {
    "type": "storage_room",
    "displayName": { "default": "Storage Room" },
    "description": {
      "default": "A cluttered backroom for keeping miscellaneous items safe — from old tools to rare potions. Protects valuable non-gear from raids."
    },
    "baseCost": { "wood": 80, "stone": 60, "iron": 20, "gold": 5 },
    "costMultiplier": { "factor": 1.2, "linear": 4 },
    "baseBuildTimeSeconds": 800,
    "buildTimeScaling": { "factor": 1.1, "linear": 25 },
    "unlockRequirement": {
      "dependsOn": "house",
      "requiredLevel": 4
    },
    "provides": {
      "maxSecuredResources": {
        "miscItems": 5
      }
    },
    "points": 5,
    "raceNames": {
      "human": "Storage Room",
      "dwarf": "Dusty Crate Hall",
      "elf": "Leaf Locker",
      "orc": "Junk Pit"
    }
  }


  {
    "type": "steward",
    "displayName": {"default": "Steward"},
    "description": {
      "default":
      "Appointing a steward allows you to manage building operations more efficiently. Each level increases your building queue capacity."
    },
    "baseCost": {"wood": 90, "stone": 60, "iron": 10, "gold": 10},
    "costMultiplier": {"factor": 1.25, "linear": 4},
    "baseBuildTimeSeconds": 600,
    "buildTimeScaling": {"factor": 1.15, "linear": 30},
    "provides": {
      "buildingQueueSlots": 1
    },
    "unlockRequirement": {
      "dependsOn": "house",
      "requiredLevel": 2
    },
    "points": 6,
    "raceNames": {
      "human": "Steward",
      "dwarf": "Mine Foreman",
      "elf": "Council Warden",
      "orc": "Whipmaster",
    },
  },


  // === WOOD CUTTER BRANCH ===


  {
    "type": "woodcutter",
    "displayName": {
      "default": "Woodcutter"
    },
    "description": {
      "default": "Foresters manage the forest near the village, balancing conservation with the need for timber. Their wood is vital for constructing buildings and forging weapons."
    },
    "baseCost": {
      "wood": 20,
      "stone": 10,
      "iron": 5,
      "gold": 0
    },
    "costMultiplier": {
      "factor": 1.2,
      "linear": 2
    },
    "baseBuildTimeSeconds": 300,
    "buildTimeScaling": {
      "factor": 1.1,
      "linear": 15
    },
    "workerPerLevel": 2,
    "provides": {
      "workers": 1,
      "maxProductionPerHour": {
        "wood": 100
      },
      "maxSecuredResources": {
        "wood": 10
      }
    },
    "points": 5,
    "raceNames": {
      "human": "Woodcutter",
      "dwarf": "Lumberjack",
      "elf": "Tree Tender",
      "orc": "Log Butcher"
    }
  }



  {
    "type": "wood_storage",
    "displayName": {"default": "Wood Storage"},
    "description": {
      "default": "Massive timber sheds protect your valuable wood from rot and the elements. Bigger stores allow you to amass enough timber for future expansions and war efforts."
    },
    "baseCost": {"wood": 50, "stone": 20, "iron": 0, "gold": 0},
    "costMultiplier": {"factor": 1.2, "linear": 4},
    "baseBuildTimeSeconds": 300,
    "buildTimeScaling": {"factor": 1.1, "linear": 15},
    "provides": {"storageCapacity": {"wood": 1000}},
    "unlockRequirement": {
      "dependsOn": "woodcutter",
      "requiredLevel": 3
    },
    "points": 4,
    "raceNames": {
      "human": "Lumber Store",
      "dwarf": "Log Vault",
      "elf": "Hollow Grove",
      "orc": "Wood Crate",
    },
  },

  {
    "type": "wood_bunker",
    "displayName": {"default": "Wood Bunker"},
    "description": {
      "default": "Hidden pits and camouflaged wood piles ensure your timber supply survives enemy raids. Only a fool leaves their wood unguarded."
    },
    "baseCost": {"wood": 60, "stone": 30, "iron": 10, "gold": 0},
    "costMultiplier": {"factor": 1.2, "linear": 3},
    "baseBuildTimeSeconds": 400,
    "buildTimeScaling": {"factor": 1.1, "linear": 20},
    "provides": {
      "maxSecuredResources": {"wood": 300}
    },
    "unlockRequirement": {
      "dependsOn": "wood_storage",
      "requiredLevel": 4
    },
    "points": 5,
    "raceNames": {
      "human": "Wood Bunker",
      "dwarf": "Hidden Stacks",
      "elf": "Forest Cache",
      "orc": "Timber Hole",
    },
  },

  {
    "type": "organization_house",
    "displayName": {"default": "Organization House"},
    "description": {
      "default": "A central office to coordinate village affairs. Improves storage handling and unlocks access to castle and economy structures."
    },
    "baseCost": {"wood": 120, "stone": 100, "iron": 20, "gold": 10},
    "costMultiplier": {"factor": 1.25, "linear": 4},
    "baseBuildTimeSeconds": 800,
    "buildTimeScaling": {"factor": 1.15, "linear": 25},
    "unlockRequirement": {
      "dependsOn": "woodcutter",
      "requiredLevel": 6
    },
    "points": 6,
    "raceNames": {
      "human": "Organization House",
      "dwarf": "Planning Hall",
      "elf": "Growth Grove",
      "orc": "Warchief Tent",
    },
  },

  {
    "type": "castle_complex",
    "displayName": {"default": "Castle Complex"},
    "description": {
      "default": "The foundation of your stronghold. Unlocks key defensive and administrative structures for your village."
    },
    "baseCost": {"wood": 180, "stone": 250, "iron": 60, "gold": 20},
    "costMultiplier": {"factor": 1.3, "linear": 6},
    "baseBuildTimeSeconds": 1200,
    "buildTimeScaling": {"factor": 1.2, "linear": 30},
    "unlockRequirement": {
      "dependsOn": "organization_house",
      "requiredLevel": 4
    },
    "points": 10,
    "raceNames": {
      "human": "Castle Complex",
      "dwarf": "Citadel Base",
      "elf": "Crystal Heart",
      "orc": "War Fortress",
    },
  },

  {
    "type": "tanner",
    "displayName": {"default": "Tanner"},
    "description": {
      "default": "A skilled artisan who turns animal hides into leather. Essential for crafting light armor and flexible gear for your heroes."
    },
    "baseCost": {"wood": 60, "stone": 30, "iron": 10, "gold": 5},
    "costMultiplier": {"factor": 1.2, "linear": 3},
    "baseBuildTimeSeconds": 500,
    "buildTimeScaling": {"factor": 1.1, "linear": 25},
    "unlockRequirement": {
      "dependsOn": "woodcutter",
      "requiredLevel": 10
    },
    "points": 6,
    "raceNames": {
      "human": "Tanner",
      "dwarf": "Hideworker",
      "elf": "Leafbinder",
      "orc": "Skin Peeler",
    },
  },

  {
    "type": "castle_moat",
    "displayName": {"default": "Castle Moat"},
    "description": {
      "default": "A deep trench filled with water or spikes, surrounding your stronghold. Slows down attackers and enhances defense."
    },
    "baseCost": {"wood": 100, "stone": 120, "iron": 10, "gold": 5},
    "costMultiplier": {"factor": 1.2, "linear": 5},
    "baseBuildTimeSeconds": 1000,
    "buildTimeScaling": {"factor": 1.15, "linear": 30},
    "unlockRequirement": {
      "dependsOn": "castle_complex",
      "requiredLevel": 1
    },
    "provides": {
      "combatStats": {
        "hp": 8,
        "defense": 30
      }
    },
    "points": 9,
    "raceNames": {
      "human": "Castle Moat",
      "dwarf": "Spike Trench",
      "elf": "Root Barrier",
      "orc": "Bone Ditch",
    },
  },

  {
    "type": "watchtower_small",
    "displayName": {"default": "Watchtower (Small)"},
    "description": {
      "default": "A basic defensive tower stationed along your castle perimeter. Offers light ranged support and increased visibility."
    },
    "baseCost": {"wood": 80, "stone": 60, "iron": 10, "gold": 0},
    "costMultiplier": {"factor": 1.2, "linear": 4},
    "baseBuildTimeSeconds": 700,
    "buildTimeScaling": {"factor": 1.1, "linear": 20},
    "unlockRequirement": {
      "dependsOn": "castle_complex",
      "requiredLevel": 2
    },
    "provides": {
      "combatStats": {
        "hp": 8,
        "attack": 18,
        "defense": 10,
        "damage": 4,
        "attackSpeed": 150000, // 150s in ms
        "expOnDestroyed": 2
      }
    },
    "points": 5,
    "raceNames": {
      "human": "Watchtower (Small)",
      "dwarf": "Guard Post",
      "elf": "Bark Spire",
      "orc": "Spear Post+",
    },
  },


  {
    "type": "watchtower_medium",
    "displayName": {"default": "Watchtower (Medium)"},
    "description": {
      "default": "A more fortified tower that offers extended sight and better defense during raids."
    },
    "baseCost": {"wood": 120, "stone": 100, "iron": 15, "gold": 0},
    "costMultiplier": {"factor": 1.25, "linear": 6},
    "baseBuildTimeSeconds": 900,
    "buildTimeScaling": {"factor": 1.15, "linear": 25},
    "unlockRequirement": {
      "dependsOn": "castle_complex",
      "requiredLevel": 4
    },
    "provides": {
      "combatStats": {
        "hp": 10,
        "attack": 20,
        "defense": 15,
        "damage": 5,
        "attackSpeed": 120000, // 120s in ms
        "expOnDestroyed": 3
      }
    },
    "points": 6,
    "raceNames": {
      "human": "Watchtower",
      "dwarf": "Stone Sentinel",
      "elf": "Vine Spire",
      "orc": "Skull Pillar",
    },
  },

  {
    "type": "barracks",
    "displayName": {"default": "Barracks"},
    "description": {
      "default": "Trains and organizes your village militia. Required to prepare and house defensive troops."
    },
    "baseCost": {"wood": 140, "stone": 110, "iron": 30, "gold": 10},
    "costMultiplier": {"factor": 1.25, "linear": 5},
    "baseBuildTimeSeconds": 1000,
    "buildTimeScaling": {"factor": 1.2, "linear": 30},
    "unlockRequirement": {
      "dependsOn": "castle_complex",
      "requiredLevel": 2
    },
    "provides": {
      "defenseSlotCapacity": 1
    },
    "points": 8,
    "raceNames": {
      "human": "Barracks",
      "dwarf": "War Hall",
      "elf": "Guard Glade",
      "orc": "Fight Pit",
    },
  },

  {
    "type": "castle_wall",
    "displayName": {"default": "Castle Wall"},
    "description": {
      "default": "Massive stone walls that fortify your stronghold and deter invaders. The backbone of any serious defense system."
    },
    "baseCost": {"wood": 200, "stone": 300, "iron": 60, "gold": 20},
    "costMultiplier": {"factor": 1.3, "linear": 8},
    "baseBuildTimeSeconds": 1500,
    "buildTimeScaling": {"factor": 1.2, "linear": 35},
    "unlockRequirement": {
      "dependsOn": "castle_complex",
      "requiredLevel": 5
    },
    "provides": {
      "combatStats": {
        "hp": 20,
        "defense": 50
      }
    },
    "points": 12,
    "raceNames": {
      "human": "Castle Wall",
      "dwarf": "Stone Shield",
      "elf": "Living Wall",
      "orc": "Bone Wall",
    },
  },

  {
    "type": "watchtower_large",
    "displayName": {"default": "Watchtower (Large)"},
    "description": {
      "default": "An imposing defensive structure with great height and visibility. Deals significant damage during sieges."
    },
    "baseCost": {"wood": 180, "stone": 200, "iron": 50, "gold": 10},
    "costMultiplier": {"factor": 1.3, "linear": 7},
    "baseBuildTimeSeconds": 1400,
    "buildTimeScaling": {"factor": 1.15, "linear": 35},
    "unlockRequirement": {
      "dependsOn": "castle_complex",
      "requiredLevel": 7
    },
    "provides": {
      "combatStats": {
        "hp": 15,
        "attack": 35,
        "defense": 25,
        "damage": 8,
        "attackSpeed": 90000, // 90s in ms
        "expOnDestroyed": 5
      }
    },
    "points": 10,
    "raceNames": {
      "human": "Grand Watchtower",
      "dwarf": "Rampart",
      "elf": "Warden Spire",
      "orc": "Skull Beacon",
    },
  },

  {
    "type": "architect_house",
    "displayName": {"default": "Architect's House"},
    "description": {
      "default": "A refined hall for planning efficient construction. Slightly reduces build times and unlocks late-game structures."
    },
    "baseCost": {"wood": 150, "stone": 180, "iron": 40, "gold": 10},
    "costMultiplier": {"factor": 1.25, "linear": 5},
    "baseBuildTimeSeconds": 1000,
    "buildTimeScaling": {"factor": 1.1, "linear": 30},
    "unlockRequirement": {
      "dependsOn": "organization_house",
      "requiredLevel": 8
    },
    "provides": {
      "constructionSpeedMultiplier": 1.02
    },
    "points": 6,
    "raceNames": {
      "human": "Architect's House",
      "dwarf": "Design Den",
      "elf": "Blueprint Glade",
      "orc": "Hammer Cave",
    },
  },

  {
    "type": "marketplace",
    "displayName": {"default": "Marketplace"},
    "description": {
      "default": "A lively center for trade and bartering. Enables resource trading and unlocks economic buildings."
    },
    "baseCost": {"wood": 160, "stone": 120, "iron": 30, "gold": 20},
    "costMultiplier": {"factor": 1.25, "linear": 6},
    "baseBuildTimeSeconds": 1000,
    "buildTimeScaling": {"factor": 1.15, "linear": 30},
    "unlockRequirement": {
      "dependsOn": "organization_house",
      "requiredLevel": 10
    },
    "provides": {
      "unlocksTrading": true
    },
    "points": 7,
    "raceNames": {
      "human": "Marketplace",
      "dwarf": "Trade Tunnel",
      "elf": "Barter Grove",
      "orc": "Loot Tent",
    },
  },

  {
    "type": "coin_stash",
    "displayName": {"default": "Coin Stash"},
    "description": {
      "default": "A secure place to hide your hard-earned gold. Protects your wealth during raids."
    },
    "baseCost": {"wood": 100, "stone": 100, "iron": 20, "gold": 0},
    "costMultiplier": {"factor": 1.2, "linear": 4},
    "baseBuildTimeSeconds": 700,
    "buildTimeScaling": {"factor": 1.1, "linear": 20},
    "unlockRequirement": {
      "dependsOn": "marketplace",
      "requiredLevel": 4
    },
    "provides": {
      "protectedFromRaid": {"gold": 100}
    },
    "points": 5,
    "raceNames": {
      "human": "Coin Stash",
      "dwarf": "Gold Vault",
      "elf": "Sun Cache",
      "orc": "Shiny Hoard",
    },
  },

  // === IRON MINE BRANCH ===


  {
    "type": "iron_mine",
    "displayName": {
      "default": "Iron Mine"
    },
    "description": {
      "default": "Miners delve deep underground to extract iron ore. The metal is used to forge tools, weapons, and armor for your warriors."
    },
    "baseCost": {
      "wood": 30,
      "stone": 5,
      "iron": 0,
      "gold": 0
    },
    "costMultiplier": {
      "factor": 1.2,
      "linear": 2
    },
    "baseBuildTimeSeconds": 300,
    "buildTimeScaling": {
      "factor": 1.1,
      "linear": 15
    },
    "workerPerLevel": 2,
    "provides": {
      "workers": 1,
      "maxProductionPerHour": {
        "iron": 60
      },
      "maxSecuredResources": {
        "iron": 10
      }
    },
    "points": 5,
    "raceNames": {
      "human": "Iron Mine",
      "dwarf": "Iron Tunnel",
      "elf": "Deep Crystal",
      "orc": "Ore Hole"
    }
  }



  {
    "type": "iron_storage",
    "displayName": {"default": "Iron Storage"},
    "description": {
      "default": "Cold and secure iron bunkers keep your metal from rust and theft. Having more storage means you can keep forging without slowing down."
    },
    "baseCost": {"wood": 40, "stone": 25, "iron": 10, "gold": 0},
    "costMultiplier": {"factor": 1.2, "linear": 4},
    "baseBuildTimeSeconds": 300,
    "buildTimeScaling": {"factor": 1.1, "linear": 15},
    "provides": {
      "storageCapacity": {"iron": 1000}
    },
    "unlockRequirement": {
      "dependsOn": "iron_mine",
      "requiredLevel": 3
    },
    "points": 4,
    "raceNames": {
      "human": "Iron Vault",
      "dwarf": "Ore Cache",
      "elf": "Moonsteel Nest",
      "orc": "Metal Heap",
    },
  },


  {
    "type": "iron_bunker",
    "displayName": {"default": "Iron Bunker"},
    "description": {
      "default": "Secured chests and buried crates hide your hard-earned iron deep underground. Defenders always protect their metal."
    },
    "baseCost": {"wood": 50, "stone": 30, "iron": 20, "gold": 0},
    "costMultiplier": {"factor": 1.2, "linear": 3},
    "baseBuildTimeSeconds": 400,
    "buildTimeScaling": {"factor": 1.1, "linear": 20},
    "provides": {
      "maxSecuredResources": {"iron": 200}
    },
    "unlockRequirement": {
      "dependsOn": "iron_storage",
      "requiredLevel": 4
    },
    "points": 5,
    "raceNames": {
      "human": "Iron Bunker",
      "dwarf": "Ore Refuge",
      "elf": "Crystal Keep",
      "orc": "Iron Heap",
    },
  },


  {
    "type": "blacksmith",
    "displayName": {"default": "Blacksmith"},
    "description": {
      "default": "A skilled artisan who forges basic gear and tools. Unlocks the ability to craft simple items and improves village armament."
    },
    "baseCost": {"wood": 100, "stone": 80, "iron": 40, "gold": 5},
    "costMultiplier": {"factor": 1.25, "linear": 5},
    "baseBuildTimeSeconds": 1000,
    "buildTimeScaling": {"factor": 1.15, "linear": 25},
    "unlockRequirement": {
      "dependsOn": "iron_mine",
      "requiredLevel": 7
    },
    "points": 8,
    "raceNames": {
      "human": "Blacksmith",
      "dwarf": "Forge Hall",
      "elf": "Blade Nest",
      "orc": "Smash Shack",
    },
  },

  {
    "type": "armory",
    "displayName": {"default": "Armory"},
    "description": {
      "default": "Stores and maintains crafted gear. Increases item capacity and unlocks basic equipment storage functionality."
    },
    "baseCost": {"wood": 100, "stone": 100, "iron": 30, "gold": 5},
    "costMultiplier": {"factor": 1.2, "linear": 4},
    "baseBuildTimeSeconds": 800,
    "buildTimeScaling": {"factor": 1.1, "linear": 25},
    "unlockRequirement": {
      "dependsOn": "blacksmith",
      "requiredLevel": 2
    },
    "provides": {
      "itemStorageSlots": 10
    },
    "points": 6,
    "raceNames": {
      "human": "Armory",
      "dwarf": "War Cache",
      "elf": "Leaf Locker",
      "orc": "Iron Cage",
    },
  },

  {
    "type": "weapon_smith",
    "displayName": {"default": "Weapon Smith"},
    "description": {
      "default": "Specializes in forging blades, axes, and ranged weapons. Unlocks offensive gear crafting options."
    },
    "baseCost": {"wood": 120, "stone": 100, "iron": 60, "gold": 10},
    "costMultiplier": {"factor": 1.25, "linear": 6},
    "baseBuildTimeSeconds": 1000,
    "buildTimeScaling": {"factor": 1.15, "linear": 30},
    "unlockRequirement": {
      "dependsOn": "blacksmith",
      "requiredLevel": 5
    },
    "provides": {
      "unlocksCraftingTypes": ["weapons"]
    },
    "points": 7,
    "raceNames": {
      "human": "Weapon Smith",
      "dwarf": "Anvil Hall",
      "elf": "Spirit Edge",
      "orc": "Chop Den",
    },
  },

  {
    "type": "armor_smith",
    "displayName": {"default": "Armor Smith"},
    "description": {
      "default": "Expert in forging defensive gear like helmets, breastplates, and shields. Unlocks armor crafting recipes."
    },
    "baseCost": {"wood": 120, "stone": 110, "iron": 70, "gold": 10},
    "costMultiplier": {"factor": 1.25, "linear": 6},
    "baseBuildTimeSeconds": 1000,
    "buildTimeScaling": {"factor": 1.15, "linear": 30},
    "unlockRequirement": {
      "dependsOn": "blacksmith",
      "requiredLevel": 6
    },
    "provides": {
      "unlocksCraftingTypes": ["armor"]
    },
    "points": 7,
    "raceNames": {
      "human": "Armor Smith",
      "dwarf": "Plate Vault",
      "elf": "Barkbinder",
      "orc": "Iron Skinner",
    },
  },

  {
    "type": "production_manager",
    "displayName": {"default": "Production Manager"},
    "description": {
      "default": "Assigns workers optimally across production tasks. Slightly boosts hourly resource output of all active producers."
    },
    "baseCost": {"wood": 150, "stone": 100, "iron": 80, "gold": 10},
    "costMultiplier": {"factor": 1.25, "linear": 5},
    "baseBuildTimeSeconds": 1000,
    "buildTimeScaling": {"factor": 1.15, "linear": 30},
    "unlockRequirement": {
      "dependsOn": "iron_mine",
      "requiredLevel": 8
    },
    "provides": {
      "productionMultiplier": 1.02 // +2% efficiency
    },
    "points": 7,
    "raceNames": {
      "human": "Production Manager",
      "dwarf": "Mining Overseer",
      "elf": "Growth Conductor",
      "orc": "Whip Foreman",
    },
  },

  {
    "type": "forge",
    "displayName": {"default": "Forge"},
    "description": {
      "default": "A blazing forge that allows crafting of advanced equipment and initiates research possibilities. Generates research points over time."
    },
    "baseCost": {"wood": 180, "stone": 140, "iron": 100, "gold": 20},
    "costMultiplier": {"factor": 1.3, "linear": 6},
    "baseBuildTimeSeconds": 1200,
    "buildTimeScaling": {"factor": 1.2, "linear": 35},
    "unlockRequirement": {
      "dependsOn": "iron_mine",
      "requiredLevel": 9
    },
    "provides": {
      "unlocksCraftingTier": 2,
      "researchPointsPerHour": 5
    },
    "points": 10,
    "raceNames": {
      "human": "Forge",
      "dwarf": "Deep Forge",
      "elf": "Sunsteel Crucible",
      "orc": "Flame Pit",
    },
  },

  {
    "type": "workshop",
    "displayName": {"default": "Workshop"},
    "description": {
      "default": "A hub for developing new crafting techniques and unlocking experimental gear blueprints."
    },
    "baseCost": {"wood": 200, "stone": 160, "iron": 120, "gold": 25},
    "costMultiplier": {"factor": 1.3, "linear": 7},
    "baseBuildTimeSeconds": 1400,
    "buildTimeScaling": {"factor": 1.2, "linear": 40},
    "unlockRequirement": {
      "dependsOn": "iron_mine",
      "requiredLevel": 12
    },
    "provides": {
      "unlocksResearch": true
    },
    "points": 10,
    "raceNames": {
      "human": "Workshop",
      "dwarf": "Gear Lab",
      "elf": "Invention Grove",
      "orc": "Bang Shack",
    },
  },

  {
    "type": "laboratory",
    "displayName": {"default": "Laboratory"},
    "description": {
      "default": "A quiet place for experimentation and theorycrafting. Unlocks structured research paths and enables potion crafting infrastructure."
    },
    "baseCost": {"wood": 180, "stone": 140, "iron": 100, "gold": 25},
    "costMultiplier": {"factor": 1.25, "linear": 5},
    "baseBuildTimeSeconds": 1200,
    "buildTimeScaling": {"factor": 1.15, "linear": 35},
    "unlockRequirement": {
      "dependsOn": "workshop",
      "requiredLevel": 2
    },
    "provides": {
      "unlocksResearch": true
    },
    "points": 8,
    "raceNames": {
      "human": "Laboratory",
      "dwarf": "Tinker Cave",
      "elf": "Grove of Insight",
      "orc": "Potion Pit",
    },
  },

  {
    "type": "alchemist",
    "displayName": {"default": "Alchemist"},
    "description": {
      "default": "A curious master of liquids and fumes. Unlocks potion crafting recipes and converts rare herbs into magical elixirs."
    },
    "baseCost": {"wood": 140, "stone": 100, "iron": 80, "gold": 20},
    "costMultiplier": {"factor": 1.25, "linear": 4},
    "baseBuildTimeSeconds": 1000,
    "buildTimeScaling": {"factor": 1.15, "linear": 30},
    "unlockRequirement": {
      "dependsOn": "laboratory",
      "requiredLevel": 3
    },
    "provides": {
      "unlocksCraftingTypes": ["potions"]
    },
    "points": 7,
    "raceNames": {
      "human": "Alchemist",
      "dwarf": "Brewmaster",
      "elf": "Essence Weaver",
      "orc": "Mushroom Stirrer",
    },
  },

  {
    "type": "herb_chamber",
    "displayName": {"default": "Herb Chamber"},
    "description": {
      "default": "Stores rare plants and herbs needed for potion making. Protects fragile ingredients and expands herb stockpiling."
    },
    "baseCost": {"wood": 100, "stone": 90, "iron": 40, "gold": 15},
    "costMultiplier": {"factor": 1.2, "linear": 4},
    "baseBuildTimeSeconds": 800,
    "buildTimeScaling": {"factor": 1.1, "linear": 25},
    "unlockRequirement": {
      "dependsOn": "laboratory",
      "requiredLevel": 5
    },
    "provides": {
      "storageCapacity": {"herbs": 500}
    },
    "points": 6,
    "raceNames": {
      "human": "Herb Chamber",
      "dwarf": "Root Crate",
      "elf": "Seed Vault",
      "orc": "Mold Locker",
    },
  },

  {
    "type": "greenhouse",
    "displayName": {"default": "Greenhouse"},
    "description": {
      "default": "A climate-controlled building for growing herbs and exotic plants. Slowly produces herbs over time for your alchemical needs."
    },
    "baseCost": {"wood": 120, "stone": 110, "iron": 50, "gold": 20},
    "costMultiplier": {"factor": 1.25, "linear": 5},
    "baseBuildTimeSeconds": 1000,
    "buildTimeScaling": {"factor": 1.15, "linear": 30},
    "unlockRequirement": {
      "dependsOn": "laboratory",
      "requiredLevel": 8
    },
    "provides": {
      "maxProductionPerHour": {"herbs": 8}
    },
    "points": 7,
    "raceNames": {
      "human": "Greenhouse",
      "dwarf": "Moss Hall",
      "elf": "Sun Pod",
      "orc": "Spore Den",
    },
  },

  // === FARM BRANCH ===

  {
    "type": "farm",
    "displayName": {"default": "Farm"},
    "description": {
      "default": "The farm is the heart of your food supply. Farmers cultivate grain, grind flour, and bake bread to feed the growing population."
    },
    "baseCost": {"wood": 30, "stone": 25, "iron": 0, "gold": 0},
    "costMultiplier": {"factor": 1.2, "linear": 2},
    "baseBuildTimeSeconds": 300,
    "buildTimeScaling": {"factor": 1.1, "linear": 15},
    "provides": {
      "maxProductionPerHour": {"food": 120}
    },
    "points": 5,
    "raceNames": {
      "human": "Farm",
      "dwarf": "Alefield",
      "elf": "Sun Garden",
      "orc": "Meat Patch",
    },
  },

  {
    "type": "healers_hut",
    "displayName": {"default": "Healer's Hut"},
    "description": {
      "default": "A basic clinic where wounded heroes and villagers can recover. Enables passive healing over time."
    },
    "baseCost": {"wood": 60, "stone": 40, "iron": 10, "gold": 5},
    "costMultiplier": {"factor": 1.2, "linear": 3},
    "baseBuildTimeSeconds": 600,
    "buildTimeScaling": {"factor": 1.1, "linear": 25},
    "unlockRequirement": {
      "dependsOn": "farm",
      "requiredLevel": 3
    },
    "provides": {
      "healingPerHour": 10
    },
    "points": 6,
    "raceNames": {
      "human": "Healer's Hut",
      "dwarf": "Ale Medic",
      "elf": "Moon Grove",
      "orc": "Wound Shack",
    },
  },

  {
    "type": "granary",
    "displayName": {"default": "Granary"},
    "description": {
      "default": "A large storehouse for your food reserves. Prevents spoilage and ensures stable supply during sieges and expansion."
    },
    "baseCost": {"wood": 90, "stone": 60, "iron": 10, "gold": 0},
    "costMultiplier": {"factor": 1.2, "linear": 4},
    "baseBuildTimeSeconds": 600,
    "buildTimeScaling": {"factor": 1.1, "linear": 25},
    "unlockRequirement": {
      "dependsOn": "farm",
      "requiredLevel": 4
    },
    "provides": {
      "storageCapacity": {"food": 1000}
    },
    "points": 5,
    "raceNames": {
      "human": "Granary",
      "dwarf": "Ale Cellar",
      "elf": "Sunroot Cache",
      "orc": "Meat Shed",
    },
  },

  {
    "type": "grain_bunker",
    "displayName": {"default": "Grain Bunker"},
    "description": {
      "default": "Underground pits and hidden vaults protect your food supply during raids. Only the toughest raiders leave fed."
    },
    "baseCost": {"wood": 70, "stone": 40, "iron": 5, "gold": 0},
    "costMultiplier": {"factor": 1.2, "linear": 4},
    "baseBuildTimeSeconds": 700,
    "buildTimeScaling": {"factor": 1.1, "linear": 25},
    "unlockRequirement": {
      "dependsOn": "granary",
      "requiredLevel": 6
    },
    "provides": {
      "maxSecuredResources": {"food": 400}
    },
    "points": 5,
    "raceNames": {
      "human": "Grain Bunker",
      "dwarf": "Root Vault",
      "elf": "Sun Cave",
      "orc": "Snack Hole",
    },
  },

  {
    "type": "wheat_fields",
    "displayName": {"default": "Wheat Fields"},
    "description": {
      "default": "A dedicated agricultural area producing a steady supply of grain for your people."
    },
    "baseCost": {"wood": 100, "stone": 80, "iron": 0, "gold": 0},
    "costMultiplier": {"factor": 1.25, "linear": 5},
    "baseBuildTimeSeconds": 900,
    "buildTimeScaling": {"factor": 1.1, "linear": 30},
    "unlockRequirement": {
      "dependsOn": "farm",
      "requiredLevel": 7
    },
    "provides": {
      "maxProductionPerHour": {"food": 150}
    },
    "points": 6,
    "raceNames": {
      "human": "Wheat Fields",
      "dwarf": "Barley Patch",
      "elf": "Sun Meadow",
      "orc": "Grain Swamp",
    },
  },

  {
    "type": "wheat_fields_large",
    "displayName": {"default": "Large Wheat Fields"},
    "description": {
      "default": "An expanded agricultural complex for mass food production. Powers your armies and growing populations."
    },
    "baseCost": {"wood": 150, "stone": 120, "iron": 10, "gold": 0},
    "costMultiplier": {"factor": 1.25, "linear": 7},
    "baseBuildTimeSeconds": 1200,
    "buildTimeScaling": {"factor": 1.2, "linear": 35},
    "unlockRequirement": {
      "dependsOn": "wheat_fields",
      "requiredLevel": 30
    },
    "provides": {
      "MaxProductionPerHour": {"food": 250}
    },
    "points": 10,
    "raceNames": {
      "human": "Large Wheat Fields",
      "dwarf": "Grand Brew Patch",
      "elf": "Solar Grove",
      "orc": "Hogback Plains",
    },
  },














];
