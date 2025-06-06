final List<Map<String, dynamic>> enemyTypes = [
  {
    'id': 'bandit',
    'name': 'Bandit',
    'description': 'A ragged outlaw with a chipped blade.',
    'combatLevel': 12,
    'baseStats': {
      'hp': 120,
      'minDamage': 8,
      'maxDamage': 14,
      'attackSpeedMs': 90000,
      'at': 18,
      'def': 14,
      'defense': 6,
    },
    'xp': 10,
    'scaleWithEvent': true,
    'source': 'Wolfgang',
  },
  {
    'id': 'goblin',
    'name': 'Goblin',
    'description':
        'A sneaky goblin with a rusty dagger and questionable hygiene.',
    'combatLevel': 8,
    'baseStats': {
      'hp': 80,
      'minDamage': 4,
      'maxDamage': 10,
      'attackSpeedMs': 75000,
      'at': 16,
      'def': 12,
      'defense': 2,
    },
    'xp': 7,
    'scaleWithEvent': true,
    'source': 'Wolfgang',
  },
  {
    'id': 'skeleton',
    'name': 'Skeleton',
    'description': 'A clattering undead warrior held together by dark magic.',
    'combatLevel': 10,
    'baseStats': {
      'hp': 100,
      'minDamage': 6,
      'maxDamage': 12,
      'attackSpeedMs': 100000,
      'at': 17,
      'def': 15,
      'defense': 4,
    },
    'xp': 9,
    'scaleWithEvent': true,
    'source': 'Wolfgang',
  },
];
