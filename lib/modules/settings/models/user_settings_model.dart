import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserSettingsModel extends ChangeNotifier {
  bool _showChatOverlay = true;
  bool get showChatOverlay => _showChatOverlay;

  bool _darkMode = false;
  bool get darkMode => _darkMode;

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  bool _hasSetDarkMode = false; // ✅ added flag to detect local change

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  UserSettingsModel() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final user = _auth.currentUser;

    if (user == null) {
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
      final data = doc.data()!;
      _showChatOverlay = data['showChatOverlay'] ?? true;

      // ✅ only overwrite darkMode if we didn't already change it
      if (!_hasSetDarkMode) {
        _darkMode = data['darkMode'] ?? false;
      }
    } else {
      await _saveSettings(); // create default settings if missing
    }

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
      'darkMode': _darkMode,
    }, SetOptions(merge: true));
  }

  Future<void> setShowChatOverlay(bool value) async {
    _showChatOverlay = value;
    notifyListeners();
    await _saveSettings();
  }

  Future<void> setDarkMode(bool value) async {
    debugPrint('🔥 setDarkMode called → $value');
    _darkMode = value;
    _hasSetDarkMode = true; // ✅ prevent load from overriding this
    notifyListeners();
    await _saveSettings();
  }
}
