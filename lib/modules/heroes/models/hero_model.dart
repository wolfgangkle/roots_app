import 'package:cloud_firestore/cloud_firestore.dart';

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
  final String tileKey;
  final Map<String, int> carriedResources;
  final String state;
  final int? destinationX;
  final int? destinationY;
  final List<Map<String, dynamic>>? movementQueue;
  final int currentWeight;
  final int hpRegen;
  final int manaRegen;
  final int foodDuration;
  final int movementSpeed;           // 🆕 New
  final int maxWaypoints;            // 🆕 New
  final int carryCapacity;
  final Map<String, dynamic> combat; // 🆕 New
  final DateTime? arrivesAt;
  final bool insideVillage;
  final DocumentReference ref;
  final String? groupId;
  final String? groupLeaderId;
  final String? guildId;
  final Timestamp? createdAt;
  final int combatLevel;


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
    required this.tileKey,
    required this.carriedResources,
    required this.state,
    required this.hpRegen,
    required this.manaRegen,
    required this.foodDuration,
    required this.movementSpeed,
    required this.maxWaypoints,
    required this.combat,
    required this.arrivesAt,
    required this.insideVillage,
    required this.ref,
    required this.createdAt,
    required this.carryCapacity,
    required this.currentWeight,
    required this.combatLevel,
    this.destinationX,
    this.destinationY,
    this.movementQueue,
    this.groupId,
    this.groupLeaderId,
    this.guildId,
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
      tileKey: data['tileKey'] ?? '${data['tileX']}_${data['tileY']}',
      carriedResources: Map<String, int>.from(data['carriedResources'] ?? {
        'wood': 0,
        'stone': 0,
        'iron': 0,
        'food': 0,
        'gold': 0,
      }),
      state: data['state'] ?? 'idle',
      hpRegen: data['hpRegen'] ?? 300,
      manaRegen: data['manaRegen'] ?? 60,
      foodDuration: data['foodDuration'] ?? 3600,
      movementSpeed: data['movementSpeed'] ?? 1000, // default fallback
      maxWaypoints: data['maxWaypoints'] ?? 5,       // default fallback
      combat: Map<String, dynamic>.from(data['combat'] ?? {
        'attackMin': 1,
        'attackMax': 2,
        'defense': 0,
        'regenPerTick': 0,
        'attackSpeedMs': 1000,
      }),
      groupId: data['groupId'],
      groupLeaderId: data['groupLeaderId'],
      guildId: data['guildId'],
      carryCapacity: data['carryCapacity'] ?? 0,
      currentWeight: data['currentWeight'] ?? 0,
      arrivesAt: data['arrivesAt']?.toDate(),
      insideVillage: data['insideVillage'] ?? false,
      destinationX: data['destinationX'],
      destinationY: data['destinationY'],
      movementQueue: (data['movementQueue'] as List<dynamic>?)
          ?.map((e) => Map<String, dynamic>.from(e))
          .toList(),
      ref: FirebaseFirestore.instance.collection('heroes').doc(id),
      createdAt: data['createdAt'],
      combatLevel: data['combatLevel'] ?? 0,

    );
  }
}
