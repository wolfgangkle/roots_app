final List<Map<String, dynamic>> encounterEvents = [
  {
    'id': 'bandit_ambush',
    'type': 'combat',
    'description': 'You’re ambushed by a pack of bandits!',
    'enemyTypes': ['bandit'],
    'minLevel': 10,
    'maxLevel': 30,
    'scale': {
      'base': 1,
      'scalePerLevel': 0.1,
      'max': 10,
    },
  },
  {
    'id': 'goblin_raid',
    'type': 'combat',
    'description': 'Goblins swarm out of the underbrush, shrieking for blood!',
    'enemyTypes': ['goblin'],
    'minLevel': 5,
    'maxLevel': 20,
    'scale': {
      'base': 2,
      'scalePerLevel': 0.2,
      'max': 12,
    },
  },
  {
    'id': 'crypt_awakening',
    'type': 'combat',
    'description': 'Bones rattle and rise as ancient skeletons awaken to your presence.',
    'enemyTypes': ['skeleton'],
    'minLevel': 8,
    'maxLevel': 25,
    'scale': {
      'base': 1,
      'scalePerLevel': 0.15,
      'max': 8,
    },
  },
  {
    'id': 'forest_crossroads',
    'type': 'combat',
    'description': 'The forest path splits — but both ends are guarded by danger. Bandits and goblins block your way!',
    'enemyTypes': ['bandit', 'goblin'],
    'minLevel': 10,
    'maxLevel': 30,
    'scale': {
      'base': 2,
      'scalePerLevel': 0.15,
      'max': 10,
    },
  },
  {
    'id': 'haunted_battlefield',
    'type': 'combat',
    'description': 'As you step onto the cursed ground, goblins scavenge the ruins while skeletons rise to defend it.',
    'enemyTypes': ['goblin', 'skeleton'],
    'minLevel': 12,
    'maxLevel': 35,
    'scale': {
      'base': 3,
      'scalePerLevel': 0.2,
      'max': 12,
    },
  },


  // peaceful events

  {
    'id': 'crystal_clear_stream',
    'type': 'peaceful',
    'description': 'You stumble upon a small, crystal-clear stream. The water sparkles unnaturally.',
    'title': 'Crystal Stream',
    'minCombatLevel': 1,
    'maxCombatLevel': 12,
    'rarity': 1,
    'reward': {
      'effect': 'restore_health',
      'xp': 8,
    },
  },
  {
    'id': 'abandoned_cart',
    'type': 'peaceful',
    'description': 'An abandoned merchant cart lies overturned. Something valuable might remain.',
    'title': 'Abandoned Cart',
    'minCombatLevel': 5,
    'maxCombatLevel': 20,
    'rarity': 2,
    'reward': {
      'effect': 'grant_gold',
      'xp': 12,
      'gold': 30,
    },
  },
  {
    'id': 'ancient_oak',
    'type': 'peaceful',
    'description': 'A towering oak radiates a strange presence. As you approach, its bark shifts subtly.',
    'title': 'Ancient Oak',
    'minCombatLevel': 8,
    'maxCombatLevel': 30,
    'rarity': 3,
    'reward': {
      'effect': 'grant_buff',
      'xp': 18,
      'buff': 'minor_protection',
    },
  }



];
