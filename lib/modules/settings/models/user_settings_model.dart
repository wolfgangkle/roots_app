// lib/modules/settings/models/user_settings_model.dart
import 'dart:ui' show Locale; // for Locale without pulling in Material
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Stores and persists user-specific UI settings (chat overlay, language, etc.).
class UserSettingsModel extends ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // 🔒 Private state
  bool _showChatOverlay = true;
  bool _isLoaded = false;

  /// Null = follow system language. Non-null = force that locale.
  Locale? _locale;

  // 🌐 Public getters
  bool get showChatOverlay => _showChatOverlay;
  bool get isLoaded => _isLoaded;
  Locale? get locale => _locale;

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

    final docRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('settings')
        .doc('main');

    final doc = await docRef.get();

    if (doc.exists) {
      final data = doc.data();
      debugPrint('📥 Firestore settings doc: $data');

      _showChatOverlay = data?['showChatOverlay'] ?? true;

      // Language handling
      final bool useSystem = (data?['useSystemLanguage'] == true);
      final String? langCode = data?['languageCode'];

      if (useSystem) {
        _locale = null; // follow system
      } else if (langCode != null && langCode.isNotEmpty) {
        _locale = Locale(langCode);
      } else {
        _locale = null; // default to system if not set
      }
    } else {
      debugPrint('📄 No settings document found. Creating default.');
      // Defaults: chat overlay ON, system language (null)
      _showChatOverlay = true;
      _locale = null;
      await _saveSettings(); // create default settings
    }

    debugPrint(
        '✅ Settings loaded → showChatOverlay: $_showChatOverlay, locale: ${_locale?.languageCode ?? 'system'}');
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('settings')
        .doc('main');

    final Map<String, Object?> update = {
      'showChatOverlay': _showChatOverlay,
      'useSystemLanguage': _locale == null,
      // Store languageCode only when a specific locale is chosen.
      'languageCode': _locale?.languageCode,
    };

    // Optional: if you prefer removing the field entirely when using system,
    // you can do this instead:
    // if (_locale == null) {
    //   update['languageCode'] = FieldValue.delete();
    // } else {
    //   update['languageCode'] = _locale!.languageCode;
    // }

    await docRef.set(update, SetOptions(merge: true));
  }

  // ——— UI actions ———

  Future<void> setShowChatOverlay(bool value) async {
    _showChatOverlay = value;
    notifyListeners();
    await _saveSettings();
  }

  /// Set a specific app language (e.g., Locale('de')) or null for system.
  Future<void> setLocale(Locale? locale) async {
    _locale = locale;
    notifyListeners();
    await _saveSettings();
  }

  /// Convenience helper to follow system language.
  Future<void> setLocaleToSystem() async => setLocale(null);
}
