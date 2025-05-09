final List<Map<String, dynamic>> spellData = [
  // === GLOBAL SPELLS ===
  {
    'id': 'burst_of_light',
    'name': 'Burst of Light',
    'type': 'combat',
    'description': 'Unleash a burst of radiant energy to damage one enemy.',
    'manaCost': 30,
    'baseEffect': {
      'damage': 20,
    },
    'scaling': {
      'type': 'linear',
      'fields': {
        'damage': {'perLevel': 5},
      }
    },
    'castContext': 'combat',
    'availableToAllRaces': true,
  },
  {
    'id': 'mend_wounds',
    'name': 'Mend Wounds',
    'type': 'utility',
    'description': 'Restore health to a target hero outside of combat.',
    'manaCost': 50,
    'baseEffect': {
      'heal': 30,
    },
    'scaling': {
      'type': 'linear',
      'fields': {
        'heal': {'perLevel': 10},
      }
    },
    'castContext': 'manual_outside_combat',
    'availableToAllRaces': true,
  },
  {
    'id': 'speed_surge',
    'name': 'Speed Surge',
    'type': 'buff',
    'description': 'Increases hero movement speed for a short duration.',
    'manaCost': 40,
    'baseEffect': {
      'speedBoost': 0.10,
      'durationMinutes': 60,
    },
    'scaling': {
      'type': 'linear',
      'fields': {
        'speedBoost': {'perLevel': 0.02, 'max': 0.3},
        'durationMinutes': {'perLevel': 10},
      }
    },
    'castContext': 'manual_outside_combat',
    'availableToAllRaces': true,
  },

  // === RACE-SPECIFIC SPELLS ===
  {
    'id': 'stone_armor',
    'name': 'Stone Armor',
    'type': 'buff',
    'description':
        'Coat an ally in magical stone, increasing their armor for hours.',
    'manaCost': 50,
    'baseEffect': {
      'armorBonus': 10,
      'durationMinutes': 180,
    },
    'scaling': {
      'type': 'linear',
      'fields': {
        'armorBonus': {'perLevel': 1},
        'durationMinutes': {'perLevel': 15},
      }
    },
    'castContext': 'manual_outside_combat',
    'availableToRaces': ['dwarf'],
  },
  {
    'id': 'natures_gift',
    'name': 'Nature\'s Gift',
    'type': 'combat',
    'description': 'Heals the lowest HP hero in combat.',
    'manaCost': 40,
    'baseEffect': {
      'heal': 15,
    },
    'scaling': {
      'type': 'linear',
      'fields': {
        'heal': {'perLevel': 5},
      }
    },
    'castContext': 'combat',
    'availableToRaces': ['elf'],
  },
  {
    'id': 'summon_atronach',
    'name': 'Summon Ice Atronach',
    'type': 'combat',
    'description': 'Summon a frozen guardian to fight for a few ticks.',
    'manaCost': 60,
    'baseEffect': {
      'hp': 100,
      'damage': 15,
      'durationTicks': 4,
    },
    'scaling': {
      'type': 'linear',
      'fields': {
        'hp': {'perLevel': 20},
        'damage': {'perLevel': 3},
        'durationTicks': {'perLevel': 0.2, 'max': 8},
      }
    },
    'castContext': 'combat',
    'availableToRaces': ['human'],
  },
];
