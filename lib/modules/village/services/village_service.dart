import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/village_model.dart';

class VillageService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  /// 🔄 Returns a stream of all villages for the current user
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
        .map((snapshot) => snapshot.docs
        .map((doc) => VillageModel.fromMap(doc.id, doc.data()))
        .toList());
  }

  /// 💾 Create or update a village
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

  /// ❌ Optional: Delete a village (not used yet)
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
}
