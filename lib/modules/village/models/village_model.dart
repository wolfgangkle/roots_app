import 'dart:math';
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

  final int freeWorkers;
  final DateTime lastUpdated;

  final Map<String, BuildingModel> buildings;
  final Map<String, int> storageCapacity;
  final Map<String, int> securedResources;

  final Map<String, num> currentProductionPerHour;

  BuildJobModel? currentBuildJob;
  final Map<String, dynamic>? currentCraftingJob;

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
    required this.freeWorkers,
    required this.lastUpdated,
    required this.buildings,
    required this.storageCapacity,
    required this.securedResources,
    required this.currentProductionPerHour,
    this.currentBuildJob,
    this.currentCraftingJob,
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

    final craftingJob = data['currentCraftingJob'] as Map<String, dynamic>?;
    final storageCap = Map<String, int>.from(data['storageCapacity'] ?? {});
    final securedRes = Map<String, int>.from(data['securedResources'] ?? {});
    final productionPerHour = Map<String, num>.from(data['currentProductionPerHour'] ?? {});

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
      freeWorkers: data['freeWorkers'] ?? 0,
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
      buildings: buildings,
      storageCapacity: storageCap,
      securedResources: securedRes,
      currentBuildJob: job,
      currentCraftingJob: craftingJob,
      currentProductionPerHour: productionPerHour,
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
      'storageCapacity': storageCapacity,
      'securedResources': securedResources,
      'freeWorkers': freeWorkers,
      'currentProductionPerHour': currentProductionPerHour,
      if (currentBuildJob != null) 'currentBuildJob': currentBuildJob!.toMap(),
      if (currentCraftingJob != null) 'currentCraftingJob': currentCraftingJob,
    };
  }

  Map<String, int> getSimulatedResources(Map<String, num> productionPerHour) {
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
      'wood': wood + (productionPerHour['wood'] ?? 0 * elapsedHours).floor(),
      'stone': stone + (productionPerHour['stone'] ?? 0 * elapsedHours).floor(),
      'food': food + (productionPerHour['food'] ?? 0 * elapsedHours).floor(),
      'iron': iron + (productionPerHour['iron'] ?? 0 * elapsedHours).floor(),
      'gold': gold + (productionPerHour['gold'] ?? 0 * elapsedHours).floor(),
    };
  }

  VillageModel copyWith({
    int? wood,
    int? stone,
    int? food,
    int? iron,
    int? gold,
    int? freeWorkers,
    DateTime? lastUpdated,
    Map<String, BuildingModel>? buildings,
    Map<String, int>? storageCapacity,
    Map<String, int>? securedResources,
    Map<String, num>? currentProductionPerHour,
    BuildJobModel? currentBuildJob,
    Map<String, dynamic>? currentCraftingJob,
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
      freeWorkers: freeWorkers ?? this.freeWorkers,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      buildings: buildings ?? this.buildings,
      storageCapacity: storageCapacity ?? this.storageCapacity,
      securedResources: securedResources ?? this.securedResources,
      currentProductionPerHour: currentProductionPerHour ?? this.currentProductionPerHour,
      currentBuildJob: currentBuildJob ?? this.currentBuildJob,
      currentCraftingJob: currentCraftingJob ?? this.currentCraftingJob,
    );
  }

  bool isBuildingUnlocked(String buildingType) {
    final def = buildingDefinitions.firstWhere(
          (b) => b['type'] == buildingType,
      orElse: () => <String, Object>{},
    );

    final unlock = def['unlockRequirement'] as Map<String, dynamic>?;
    if (unlock == null) return true;

    final dependency = unlock['dependsOn'] as String;
    final requiredLevel = unlock['requiredLevel'] as int;
    final dependencyLevel = buildings[dependency]?.level ?? 0;

    return dependencyLevel >= requiredLevel;
  }

  List<String> getUnlockedBuildings() {
    return buildingDefinitions
        .where((b) => isBuildingUnlocked(b['type'] as String))
        .map((b) => b['type'] as String)
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

  void simulateUpgrade(String buildingType) {
    final currentLevel = buildings[buildingType]?.level ?? 0;
    final targetLevel = currentLevel + 1;

    final def = buildingDefinitions.firstWhere(
          (b) => b['type'] == buildingType,
      orElse: () => <String, Object>{},
    );

    final base = def['baseBuildTimeSeconds'] as int? ?? 30;
    final buildTimeScaling =
        def['buildTimeScaling'] as Map<String, dynamic>? ?? {};
    final factor = buildTimeScaling['factor'] ?? 1.0;
    final linear = buildTimeScaling['linear'] ?? 0;

    final seconds =
    (base * pow(targetLevel, factor) + (targetLevel * linear)).round();
    final estimatedDuration = Duration(seconds: seconds);

    final simulatedJob = BuildJobModel(
      buildingType: buildingType,
      targetLevel: targetLevel,
      startedAt: DateTime.now(),
      durationSeconds: estimatedDuration.inSeconds,
    );

    buildings[buildingType] =
        BuildingModel(type: buildingType, level: currentLevel);
    currentBuildJob = simulatedJob;
  }

  void cancelSimulatedUpgrade() {
    currentBuildJob = null;
  }
}
