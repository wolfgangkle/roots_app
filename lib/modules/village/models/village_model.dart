import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roots_app/modules/village/models/building_model.dart';
import '../data/building_definitions.dart';


class VillageModel {
  final String id;
  final String name;
  final int tileX;
  final int tileY;

  final int wood;
  final int stone;
  final int food;
  final int iron;
  final int gold;

  final DateTime lastUpdated;
  final Map<String, BuildingModel> buildings;

  VillageModel({
    required this.id,
    required this.name,
    required this.tileX,
    required this.tileY,
    required this.wood,
    required this.stone,
    required this.food,
    required this.iron,
    required this.gold,
    required this.lastUpdated,
    required this.buildings,
  });

  factory VillageModel.fromMap(String id, Map<String, dynamic> data) {
    final resources = data['resources'] ?? {};
    final buildingsMap = data['buildings'] as Map<String, dynamic>? ?? {};

    final Map<String, BuildingModel> buildings = {};
    buildingsMap.forEach((type, value) {
      buildings[type] = BuildingModel.fromMap(type, value);
    });

    return VillageModel(
      id: id,
      name: data['name'] ?? 'Unnamed',
      tileX: data['tileX'] ?? 0,
      tileY: data['tileY'] ?? 0,
      wood: (resources['wood'] ?? 0) as int,
      stone: (resources['stone'] ?? 0) as int,
      food: (resources['food'] ?? 0) as int,
      iron: (resources['iron'] ?? 0) as int,
      gold: (resources['gold'] ?? 0) as int,
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
      buildings: buildings,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'tileX': tileX,
      'tileY': tileY,
      'lastUpdated': lastUpdated,
      'resources': {
        'wood': wood,
        'stone': stone,
        'food': food,
        'iron': iron,
        'gold': gold,
      },
      'buildings': buildings.map((key, value) => MapEntry(key, value.toMap())),
    };
  }

  /// Calculates updated resource values based on production since lastUpdated
  Map<String, int> calculateCurrentResources() {
    final now = DateTime.now();
    final elapsedMinutes = now.difference(lastUpdated).inMinutes;
    final elapsedHours = elapsedMinutes / 60;

    // Get production rates from buildings
    final woodPerHour = buildings['woodcutter']?.productionPerHour ?? 0;
    final stonePerHour = buildings['quarry']?.productionPerHour ?? 0;
    final foodPerHour = buildings['farm']?.productionPerHour ?? 0;

    return {
      'wood': wood + (woodPerHour * elapsedHours).floor(),
      'stone': stone + (stonePerHour * elapsedHours).floor(),
      'food': food + (foodPerHour * elapsedHours).floor(),
      'iron': iron, // No production building yet
      'gold': gold, // Not produced
    };
  }

  /// Returns a copy of this model with updated fields
  VillageModel copyWith({
    int? wood,
    int? stone,
    int? food,
    int? iron,
    int? gold,
    DateTime? lastUpdated,
    Map<String, BuildingModel>? buildings,
  }) {
    return VillageModel(
      id: id,
      name: name,
      tileX: tileX,
      tileY: tileY,
      wood: wood ?? this.wood,
      stone: stone ?? this.stone,
      food: food ?? this.food,
      iron: iron ?? this.iron,
      gold: gold ?? this.gold,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      buildings: buildings ?? this.buildings,
    );
  }

  /// Checks if a building is unlocked based on the techtree logic
  bool isBuildingUnlocked(String buildingType) {
    final definition = buildingDefinitions[buildingType];
    if (definition == null) return false;

    final unlock = definition.unlockRequirement;
    if (unlock == null) return true;

    final dependencyLevel = buildings[unlock.dependsOn]?.level ?? 0;
    return dependencyLevel >= unlock.requiredLevel;
  }

  /// Returns a list of building types that are unlocked and available to display
  List<String> getUnlockedBuildings() {
    return buildingDefinitions.entries
        .where((entry) => isBuildingUnlocked(entry.key))
        .map((entry) => entry.key)
        .toList();
  }
}
