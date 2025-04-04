import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:roots_app/modules/village/models/village_model.dart';
import 'package:roots_app/modules/village/models/building_model.dart';
import 'package:roots_app/modules/village/data/building_definitions.dart';
import 'package:roots_app/utils/firestore_logger.dart';

class VillageService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Stream<List<VillageModel>> getVillagesStream() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("No user logged in");
    }

    final stream = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('villages')
        .snapshots();

    // Not logging here, because snapshot listeners count as reads automatically per doc.

    return stream.asyncMap((snapshot) async {
      final villages = snapshot.docs
          .map((doc) {
        FirestoreLogger.read("getVillagesStream -> doc: ${doc.id}");
        return VillageModel.fromMap(doc.id, doc.data());
      })
          .toList();

      for (final village in villages) {
        await syncVillageResources(village);
      }

      return villages;
    });
  }

  Stream<VillageModel> getVillageStream(String villageId) {
    final user = _auth.currentUser;
    if (user == null) throw Exception("No user logged in");

    final stream = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('villages')
        .doc(villageId)
        .snapshots();

    return stream.map((doc) {
      FirestoreLogger.read("getVillageStream($villageId)");
      return VillageModel.fromMap(doc.id, doc.data()!);
    });
  }

  Future<void> saveVillage(VillageModel village) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Not logged in");

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('villages')
        .doc(village.id)
        .set(village.toMap());

    FirestoreLogger.write("saveVillage(${village.id})");
  }

  Future<void> deleteVillage(String villageId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Not logged in");

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('villages')
        .doc(villageId)
        .delete();

    FirestoreLogger.delete("deleteVillage($villageId)");
  }

  Future<void> startBuildingUpgrade({
    required String villageId,
    required String buildingType,
    required int targetLevel,
    required Duration duration,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Not logged in");

    final now = DateTime.now();

    final villageDocRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('villages')
        .doc(villageId);

    final villageDoc = await villageDocRef.get();
    FirestoreLogger.read("startBuildingUpgrade → get($villageId)");

    if (!villageDoc.exists) throw Exception("Village not found");
    final data = villageDoc.data()!;
    final resources = (data['resources'] as Map<String, dynamic>?) ?? {};

    final def = buildingDefinitions[buildingType];
    if (def == null) throw Exception("Invalid building: $buildingType");
    final cost = def.getCostForLevel(targetLevel);

    final newWood = (resources['wood'] ?? 0) - (cost['wood'] ?? 0);
    final newStone = (resources['stone'] ?? 0) - (cost['stone'] ?? 0);
    final newFood = (resources['food'] ?? 0) - (cost['food'] ?? 0);
    final newIron = (resources['iron'] ?? 0) - (cost['iron'] ?? 0);
    final newGold = (resources['gold'] ?? 0) - (cost['gold'] ?? 0);

    if (newWood < 0 ||
        newStone < 0 ||
        newFood < 0 ||
        newIron < 0 ||
        newGold < 0) {
      throw Exception("Not enough resources");
    }

    await villageDocRef.update({
      'currentBuildJob': {
        'buildingType': buildingType,
        'startedAt': Timestamp.fromDate(now),
        'durationSeconds': duration.inSeconds,
        'targetLevel': targetLevel,
      },
      'resources': {
        'wood': newWood,
        'stone': newStone,
        'food': newFood,
        'iron': newIron,
        'gold': newGold,
      },
    });

    FirestoreLogger.write("startBuildingUpgrade($villageId → $buildingType L$targetLevel)");
  }

  Future<void> finishBuildingUpgrade({
    required String villageId,
    required String buildingType,
    required int newLevel,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Not logged in");

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('villages')
        .doc(villageId)
        .update({
      'buildings.$buildingType.level': newLevel,
      'currentBuildJob': FieldValue.delete(),
    });

    FirestoreLogger.write("finishBuildingUpgrade($villageId → $buildingType → L$newLevel)");
  }

  Future<void> queueUpgradeForBuilding({
    required String villageId,
    required String buildingType,
    required int currentLevel,
  }) async {
    final def = buildingDefinitions[buildingType];
    if (def == null) throw Exception("Invalid building: $buildingType");

    final targetLevel = currentLevel + 1;
    final seconds =
    (30 * sqrt((targetLevel * targetLevel).toDouble())).round();
    final duration = Duration(seconds: seconds);

    await startBuildingUpgrade(
      villageId: villageId,
      buildingType: buildingType,
      targetLevel: targetLevel,
      duration: duration,
    );
  }

  Future<VillageModel> applyPendingUpgradeIfNeeded(VillageModel village) async {
    final job = village.currentBuildJob;
    if (job == null || !job.isComplete) return village;

    final type = job.buildingType;
    final currentLevel = village.buildings[type]?.level ?? 0;
    final targetLevel = job.targetLevel;

    if (currentLevel >= targetLevel) {
      await finishBuildingUpgrade(
        villageId: village.id,
        buildingType: type,
        newLevel: currentLevel,
      );
      return village.copyWith(
        currentBuildJob: null,
        lastUpdated: DateTime.now(),
      );
    }

    final updatedBuildings =
    Map<String, BuildingModel>.from(village.buildings)
      ..[type] = BuildingModel(type: type, level: targetLevel);

    await finishBuildingUpgrade(
      villageId: village.id,
      buildingType: type,
      newLevel: targetLevel,
    );

    return village.copyWith(
      buildings: updatedBuildings,
      currentBuildJob: null,
      lastUpdated: DateTime.now(),
    );
  }

  Future<void> syncVillageResources(VillageModel village) async {
    final updatedResources = village.calculateCurrentResources();
    final upgradeFinished = village.currentBuildJob?.isComplete ?? false;

    final bool hasChanges =
        updatedResources['wood'] != village.wood ||
            updatedResources['stone'] != village.stone ||
            updatedResources['food'] != village.food ||
            updatedResources['iron'] != village.iron ||
            updatedResources['gold'] != village.gold;

    final elapsed = DateTime.now().difference(village.lastUpdated);

    if (!hasChanges && !upgradeFinished && elapsed.inSeconds < 60) return;

    if (upgradeFinished) {
      await applyPendingUpgradeIfNeeded(village);
      return;
    }

    final updatedVillage = village.copyWith(
      wood: updatedResources['wood'],
      stone: updatedResources['stone'],
      food: updatedResources['food'],
      iron: updatedResources['iron'],
      gold: updatedResources['gold'],
      lastUpdated: DateTime.now(),
    );

    await saveVillage(updatedVillage);
  }

  Future<void> createTestVillage() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Not logged in");

    final newDoc = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('villages')
        .doc();

    final village = VillageModel(
      id: newDoc.id,
      name: 'Test Village',
      tileX: DateTime.now().millisecondsSinceEpoch % 100,
      tileY: DateTime.now().millisecondsSinceEpoch % 100,
      wood: 300,
      stone: 200,
      food: 250,
      iron: 80,
      gold: 50,
      lastUpdated: DateTime.now(),
      buildings: {
        'woodcutter': BuildingModel(type: 'woodcutter', level: 1),
        'quarry': BuildingModel(type: 'quarry', level: 1),
      },
    );

    await saveVillage(village);
    FirestoreLogger.write("createTestVillage → ${village.id}");
  }

  Future<VillageModel> getVillage(String villageId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Not logged in");

    final doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('villages')
        .doc(villageId)
        .get();

    FirestoreLogger.read("getVillage($villageId)");

    if (!doc.exists) {
      throw Exception("Village not found");
    }

    return VillageModel.fromMap(doc.id, doc.data()!);
  }
}
