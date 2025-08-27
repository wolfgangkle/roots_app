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

  // Movement / capacity
  final int movementSpeed;
  final int maxWaypoints;
  final int carryCapacity;
  final double? baseMovementSpeed; // optional: preview uses

  // Combat bundle
  final Map<String, dynamic> combat;

  final DateTime? arrivesAt;
  final bool insideVillage;
  final DocumentReference ref;
  final String? groupId;
  final String? groupLeaderId;
  final String? guildId;

  // Timestamps / meta
  final Timestamp? createdAt;
  final Timestamp? updatedAt; // used to detect freshness in UI

  // Level/combat meta
  final int combatLevel;

  // Level-up flow fields (optional, added by backend)
  final int? unspentAttributePoints;
  final bool? pendingLevelUp;

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
    this.updatedAt,
    this.unspentAttributePoints,
    this.pendingLevelUp,
    this.baseMovementSpeed,
  });

  factory HeroModel.fromFirestore(String id, Map<String, dynamic> data) {
    Map<String, int> parseIntMap(dynamic raw) {
      if (raw is Map) {
        final result = <String, int>{};
        raw.forEach((k, v) {
          if (v is num) {
            result[k.toString()] = v.toInt();
          } else if (v is String) {
            final parsed = int.tryParse(v);
            if (parsed != null) result[k.toString()] = parsed;
          }
        });
        return result;
      }
      return const {};
    }

    int parseInt(dynamic value, [int fallback = 0]) {
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? fallback;
      return fallback;
    }

    double? parseDoubleOrNull(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    Timestamp? ts(dynamic v) {
      if (v is Timestamp) return v;
      if (v is DateTime) return Timestamp.fromDate(v);
      return null;
    }

    DateTime? toDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return null;
    }

    // Combat defaults first; then override with server map (if present).
    final Map<String, dynamic> combat = {
      'attackMin': 1,
      'attackMax': 2,
      'defense': 0,
      'regenPerTick': 0,
      'attackSpeedMs': 1000,
      'at': 0,
      'def': 0,
      if (data['combat'] is Map) ...Map<String, dynamic>.from(data['combat']),
    };

    return HeroModel(
      id: id,
      ownerId: (data['ownerId'] as String?) ?? '',
      heroName: (data['heroName'] as String?) ?? 'Unnamed',
      race: (data['race'] as String?) ?? 'Unknown',
      type: (data['type'] as String?) ?? 'mage',
      level: parseInt(data['level'], 1),
      experience: parseInt(data['experience']),
      hp: parseInt(data['hp'], 100),
      hpMax: parseInt(data['hpMax'], 100),
      mana: parseInt(data['mana'], 50),
      manaMax: parseInt(data['manaMax'], 50),
      magicResistance: parseInt(data['magicResistance']),
      stats: parseIntMap(data['stats']),
      tileX: parseInt(data['tileX']),
      tileY: parseInt(data['tileY']),
      tileKey: (data['tileKey'] as String?) ??
          '${parseInt(data['tileX'])}_${parseInt(data['tileY'])}',
      carriedResources: parseIntMap(data['carriedResources']),
      state: (data['state'] as String?) ?? 'idle',
      hpRegen: parseInt(data['hpRegen'], 300),
      manaRegen: parseInt(data['manaRegen'], 60),
      foodDuration: parseInt(data['foodDuration'], 3600),

      movementSpeed: parseInt(data['movementSpeed'], 1000),
      maxWaypoints: parseInt(data['maxWaypoints'], 5),
      carryCapacity: parseInt(data['carryCapacity']),
      baseMovementSpeed: parseDoubleOrNull(data['baseMovementSpeed']),

      combat: combat,

      groupId: data['groupId'] as String?,
      groupLeaderId: data['groupLeaderId'] as String?,
      guildId: data['guildId'] as String?,

      currentWeight: parseInt(data['currentWeight']),
      arrivesAt: toDate(data['arrivesAt']),
      insideVillage: (data['insideVillage'] as bool?) ?? false,

      destinationX: (data['destinationX'] is num)
          ? (data['destinationX'] as num).toInt()
          : null,
      destinationY: (data['destinationY'] is num)
          ? (data['destinationY'] as num).toInt()
          : null,

      movementQueue: (data['movementQueue'] is List)
          ? (data['movementQueue'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList()
          : null,

      ref: FirebaseFirestore.instance.collection('heroes').doc(id),
      createdAt: ts(data['createdAt']),
      updatedAt: ts(data['updatedAt']),

      combatLevel: parseInt(data['combatLevel']),

      unspentAttributePoints: (data['unspentAttributePoints'] is num)
          ? (data['unspentAttributePoints'] as num).toInt()
          : ((data['unspentAttributePoints'] is String)
          ? int.tryParse(data['unspentAttributePoints']) ?? 0
          : null),

      pendingLevelUp: data['pendingLevelUp'] is bool
          ? data['pendingLevelUp'] as bool
          : null,
    );
  }
}
