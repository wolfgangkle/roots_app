class HeroModel {
  final String id;
  final String ownerId;
  final String heroName;
  final String race;
  final String type;
  final int level;
  final int experience;
  final int hp;
  final int hpMax;
  final int mana;
  final int manaMax;
  final int magicResistance;
  final Map<String, int> stats;
  final int tileX;
  final int tileY;
  final String state;

  // 🆕 new fields
  final int hpRegen;
  final int manaRegen;
  final int foodDuration;

  HeroModel({
    required this.id,
    required this.ownerId,
    required this.heroName,
    required this.race,
    required this.type,
    required this.level,
    required this.experience,
    required this.hp,
    required this.hpMax,
    required this.mana,
    required this.manaMax,
    required this.magicResistance,
    required this.stats,
    required this.tileX,
    required this.tileY,
    required this.state,
    required this.hpRegen,
    required this.manaRegen,
    required this.foodDuration,
  });

  factory HeroModel.fromFirestore(String id, Map<String, dynamic> data) {
    return HeroModel(
      id: id,
      ownerId: data['ownerId'],
      heroName: data['heroName'] ?? 'Unnamed',
      race: data['race'] ?? 'Unknown',
      type: data['type'] ?? 'mage',
      level: data['level'] ?? 1,
      experience: data['experience'] ?? 0,
      hp: data['hp'] ?? 100,
      hpMax: data['hpMax'] ?? 100,
      mana: data['mana'] ?? 50,
      manaMax: data['manaMax'] ?? 50,
      magicResistance: data['magicResistance'] ?? 0,
      stats: Map<String, int>.from(data['stats'] ?? {
        'strength': 10,
        'dexterity': 10,
        'intelligence': 10,
        'constitution': 10,
      }),
      tileX: data['tileX'] ?? 0,
      tileY: data['tileY'] ?? 0,
      state: data['state'] ?? 'idle',

      // 🧙 pull new values from Firestore
      hpRegen: data['hpRegen'] ?? 300,
      manaRegen: data['manaRegen'] ?? 60,
      foodDuration: data['foodDuration'] ?? 3600,
    );
  }
}
