import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserSettingsModel extends ChangeNotifier {
  bool _showChatOverlay = true;
  bool get showChatOverlay => _showChatOverlay;

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  UserSettingsModel() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('settings')
        .doc('main')
        .get();

    if (doc.exists) {
      _showChatOverlay = doc.data()?['showChatOverlay'] ?? true;
      notifyListeners();
    } else {
      await _saveSettings(); // Create default settings if missing
    }
  }

  Future<void> _saveSettings() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('settings')
        .doc('main')
        .set({
      'showChatOverlay': _showChatOverlay,
    }, SetOptions(merge: true));
  }

  Future<void> setShowChatOverlay(bool value) async {
    _showChatOverlay = value;
    notifyListeners();
    await _saveSettings();
  }
}
