import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:roots_app/modules/village/models/village_model.dart';
import 'package:roots_app/modules/village/models/building_model.dart';
import 'package:roots_app/modules/village/data/building_definitions.dart';

class VillageService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  /// 🔄 Returns a stream of all villages for the current user.
  Stream<List<VillageModel>> getVillagesStream() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("No user logged in");
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('villages')
        .snapshots()
        .asyncMap((snapshot) async {
      final villages = snapshot.docs
          .map((doc) => VillageModel.fromMap(doc.id, doc.data()))
          .toList();

      // 💾 Auto-finish upgrades and sync resources for each village.
      for (final village in villages) {
        await syncVillageResources(village);
      }

      return villages;
    });
  }

  /// Returns a stream of a single village by its ID.
  Stream<VillageModel> getVillageStream(String villageId) {
    final user = _auth.currentUser;
    if (user == null) throw Exception("No user logged in");

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('villages')
        .doc(villageId)
        .snapshots()
        .map((doc) => VillageModel.fromMap(doc.id, doc.data()!));
  }

  /// 💾 Create or update a village.
  Future<void> saveVillage(VillageModel village) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Not logged in");

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('villages')
        .doc(village.id)
        .set(village.toMap());
  }

  /// ❌ Optional: Delete a village (not used yet).
  Future<void> deleteVillage(String villageId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Not logged in");

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('villages')
        .doc(villageId)
        .delete();
  }

  /// 🏗️ Start an upgrade (adds upgrade job with timestamps).
  Future<void> startBuildingUpgrade({
    required String villageId,
    required String buildingType,
    required int targetLevel,
    required Duration duration,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Not logged in");

    final now = DateTime.now();

    // Get a reference to the village document.
    final villageDocRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('villages')
        .doc(villageId);

    // Retrieve the current village data.
    final villageDoc = await villageDocRef.get();
    if (!villageDoc.exists) throw Exception("Village not found");
    final data = villageDoc.data()!;
    final resources = (data['resources'] as Map<String, dynamic>?) ?? {};

    // Calculate the upgrade cost from the building definition.
    final def = buildingDefinitions[buildingType];
    if (def == null) throw Exception("Invalid building: $buildingType");
    final cost = def.getCostForLevel(targetLevel);

    // Subtract the cost from each resource.
    final newWood = (resources['wood'] ?? 0) - (cost['wood'] ?? 0);
    final newStone = (resources['stone'] ?? 0) - (cost['stone'] ?? 0);
    final newFood = (resources['food'] ?? 0) - (cost['food'] ?? 0);
    final newIron = (resources['iron'] ?? 0) - (cost['iron'] ?? 0);
    final newGold = (resources['gold'] ?? 0) - (cost['gold'] ?? 0);

    // Optional: Check if any new resource value is negative.
    if (newWood < 0 ||
        newStone < 0 ||
        newFood < 0 ||
        newIron < 0 ||
        newGold < 0) {
      throw Exception("Not enough resources");
    }

    // Update the document with both the upgrade job and the new resource values.
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
  }

  /// ✅ Finish upgrade (writes new level + removes upgrade job).
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
  }

  /// 🧮 Wrapper that calculates upgrade duration and starts upgrade.
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

  /// 🔁 Auto-finish upgrade if complete.
  Future<VillageModel> applyPendingUpgradeIfNeeded(VillageModel village) async {
    final job = village.currentBuildJob;
    if (job == null || !job.isComplete) return village;

    final type = job.buildingType;
    final currentLevel = village.buildings[type]?.level ?? 0;
    final targetLevel = job.targetLevel;

    // If the building is already upgraded to or beyond the target, clear the job.
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

    // Otherwise, upgrade the building to the target level and clear the job.
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
      currentBuildJob: null, // Clear the job.
      lastUpdated: DateTime.now(),
    );
  }

  /// ⏱️ Sync resources and finish upgrade if done.
  Future<void> syncVillageResources(VillageModel village) async {
    final updatedResources = village.calculateCurrentResources();
    final upgradeFinished = village.currentBuildJob?.isComplete ?? false;

    // Determine if there are resource changes.
    final bool hasChanges =
        updatedResources['wood'] != village.wood ||
            updatedResources['stone'] != village.stone ||
            updatedResources['food'] != village.food ||
            updatedResources['iron'] != village.iron ||
            updatedResources['gold'] != village.gold;

    final elapsed = DateTime.now().difference(village.lastUpdated);

    // If nothing significant changed and no upgrade is finished, skip the update.
    if (!hasChanges && !upgradeFinished && elapsed.inSeconds < 60) return;

    // If an upgrade is finished, apply it and return immediately.
    if (upgradeFinished) {
      await applyPendingUpgradeIfNeeded(village);
      return;
    }

    // Otherwise, update the resource values (and lastUpdated).
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

  /// 🧪 TEMP: Create a test village manually.
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
  }

  /// 🔍 Fetch a single village by its ID.
  Future<VillageModel> getVillage(String villageId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Not logged in");

    final doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('villages')
        .doc(villageId)
        .get();

    if (!doc.exists) {
      throw Exception("Village not found");
    }

    return VillageModel.fromMap(doc.id, doc.data()!);
  }
}
