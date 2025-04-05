import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:roots_app/modules/village/models/village_model.dart';
import 'package:roots_app/modules/village/models/building_model.dart';
import 'package:roots_app/utils/firestore_logger.dart';

class VillageService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Stream<List<VillageModel>> getVillagesStream() {
    final user = _auth.currentUser;
    if (user == null) throw Exception("No user logged in");

    final stream = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('villages')
        .snapshots();

    return stream.map((snapshot) {
      return snapshot.docs.map((doc) {
        FirestoreLogger.read("getVillagesStream -> doc: ${doc.id}");
        return VillageModel.fromMap(doc.id, doc.data());
      }).toList();
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

  Future<List<VillageModel>> getVillagesOnce() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("No user logged in");

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('villages')
        .get();

    FirestoreLogger.read("getVillagesOnce (all villages)");

    return snapshot.docs.map((doc) {
      return VillageModel.fromMap(doc.id, doc.data());
    }).toList();
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

  /// 🔄 Calls backend function to start a building upgrade
  Future<void> startUpgradeViaBackend({
    required String villageId,
    required String buildingType,
  }) async {
    final callable = FirebaseFunctions.instance.httpsCallable('startBuildingUpgrade');

    await callable.call({
      'villageId': villageId,
      'buildingType': buildingType,
    });

    FirestoreLogger.write("startUpgradeViaBackend($villageId → $buildingType)");
  }

  Future<void> createTestVillage() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Not logged in");

    final newDoc = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('villages')
        .doc();

    final now = DateTime.now();

    final villageData = {
      'name': 'Test Village',
      'tileX': now.millisecondsSinceEpoch % 100,
      'tileY': now.millisecondsSinceEpoch % 100,
      'lastUpdated': Timestamp.fromDate(now),
      'resources': {
        'wood': 300,
        'stone': 200,
        'food': 250,
        'iron': 80,
        'gold': 50,
      },
      'buildings': {
        'woodcutter': {'level': 1},
        'quarry': {'level': 1},
      },
      'productionPerHour': {
        'wood': 100,
        'stone': 80,
        'food': 0,
        'iron': 0,
        'gold': 0,
      },
    };

    await newDoc.set(villageData);
    FirestoreLogger.write("createTestVillage → ${newDoc.id}");
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
