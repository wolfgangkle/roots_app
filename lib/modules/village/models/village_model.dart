import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roots_app/modules/village/models/building_model.dart';
import 'package:roots_app/modules/village/models/build_job_model.dart';
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
  final BuildJobModel? currentBuildJob;

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
    this.currentBuildJob,
  });

  factory VillageModel.fromMap(String id, Map<String, dynamic> data) {
    final resources = data['resources'] ?? {};
    final buildingsMap = data['buildings'] as Map<String, dynamic>? ?? {};

    final Map<String, BuildingModel> buildings = {};
    buildingsMap.forEach((type, value) {
      buildings[type] = BuildingModel.fromMap(type, value);
    });

    final jobData = data['currentBuildJob'];
    final BuildJobModel? job =
    jobData != null ? BuildJobModel.fromMap(jobData) : null;

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
      currentBuildJob: job,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'tileX': tileX,
      'tileY': tileY,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'resources': {
        'wood': wood,
        'stone': stone,
        'food': food,
        'iron': iron,
        'gold': gold,
      },
      'buildings': buildings.map((key, value) => MapEntry(key, value.toMap())),
      if (currentBuildJob != null)
        'currentBuildJob': currentBuildJob!.toMap(),
    };
  }

  Map<String, int> getSimulatedResources(Map<String, int> productionPerHour) {
    final now = DateTime.now();
    final elapsedMinutes = now.difference(lastUpdated).inMinutes;

    if (elapsedMinutes < 1) {
      return {
        'wood': wood,
        'stone': stone,
        'food': food,
        'iron': iron,
        'gold': gold,
      };
    }

    final elapsedHours = elapsedMinutes / 60.0;

    return {
      'wood': wood + (productionPerHour['wood'] ?? 0) * elapsedHours ~/ 1,
      'stone': stone + (productionPerHour['stone'] ?? 0) * elapsedHours ~/ 1,
      'food': food + (productionPerHour['food'] ?? 0) * elapsedHours ~/ 1,
      'iron': iron + (productionPerHour['iron'] ?? 0) * elapsedHours ~/ 1,
      'gold': gold + (productionPerHour['gold'] ?? 0) * elapsedHours ~/ 1,
    };
  }

  VillageModel copyWith({
    int? wood,
    int? stone,
    int? food,
    int? iron,
    int? gold,
    DateTime? lastUpdated,
    Map<String, BuildingModel>? buildings,
    BuildJobModel? currentBuildJob,
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
      currentBuildJob: currentBuildJob ?? this.currentBuildJob,
    );
  }

  bool isBuildingUnlocked(String buildingType) {
    final definition = buildingDefinitions[buildingType];
    if (definition == null) return false;

    final unlock = definition.unlockRequirement;
    if (unlock == null) return true;

    final dependencyLevel = buildings[unlock.dependsOn]?.level ?? 0;
    return dependencyLevel >= unlock.requiredLevel;
  }

  List<String> getUnlockedBuildings() {
    return buildingDefinitions.entries
        .where((entry) => isBuildingUnlocked(entry.key))
        .map((entry) => entry.key)
        .toList();
  }

  bool hasOngoingBuild() {
    return currentBuildJob != null && !currentBuildJob!.isComplete;
  }

  Duration? getRemainingBuildTime() {
    if (currentBuildJob == null) return null;
    final now = DateTime.now();
    final endTime = currentBuildJob!.startedAt.add(
      Duration(seconds: currentBuildJob!.durationSeconds),
    );
    return endTime.isAfter(now) ? endTime.difference(now) : Duration.zero;
  }
}
