import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Stores and persists user-specific UI settings like chat overlay visibility.
class UserSettingsModel extends ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // 🔒 Private state
  bool _showChatOverlay = true;
  bool _isLoaded = false;

  // 🌐 Public getters
  bool get showChatOverlay => _showChatOverlay;
  bool get isLoaded => _isLoaded;

  // 🧠 Load initial settings from Firestore
  UserSettingsModel() {
    debugPrint('🛠️ UserSettingsModel constructor called');
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    debugPrint('📦 _loadSettings() started');

    // 🔄 Wait for Firebase Auth to provide a user
    User? user;
    int retries = 0;
    while (user == null && retries < 20) {
      await Future.delayed(const Duration(milliseconds: 100));
      user = _auth.currentUser;
      retries++;
    }

    if (user == null) {
      debugPrint('🚫 No current user after waiting — skipping settings load.');
      _isLoaded = true;
      notifyListeners();
      return;
    }

    final doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('settings')
        .doc('main')
        .get();

    if (doc.exists) {
      final data = doc.data();
      debugPrint('📥 Firestore settings doc: $data');

      _showChatOverlay = data?['showChatOverlay'] ?? true;
    } else {
      debugPrint('📄 No settings document found. Creating default.');
      await _saveSettings(); // create default settings
    }

    debugPrint('✅ Settings loaded → showChatOverlay: $_showChatOverlay');
    _isLoaded = true;
    notifyListeners();
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
