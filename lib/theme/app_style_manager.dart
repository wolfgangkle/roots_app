import 'package:flutter/material.dart';
import 'tokens.dart';
import 'dark_forge.dart';
import 'silver_grove.dart';
import 'iron_keep.dart'; // 👈 new solid medieval preset

/// Enum for your selectable themes
enum AppTheme {
  darkForge,
  silverGrove,
  ironKeep, // 👈 add enum
}

/// Global tokens reference for legacy callers.
/// It stays in sync with StyleManager.
AppStyleTokens kStyle = darkForge;

class StyleManager extends ChangeNotifier {
  AppTheme _current = AppTheme.darkForge;

  static final Map<AppTheme, AppStyleTokens> _styles = {
    AppTheme.darkForge: darkForge,
    AppTheme.silverGrove: silverGrove,
    AppTheme.ironKeep: ironKeep, // 👈 register the new theme
  };

  /// Read the active tokens (for widgets using Provider)
  AppStyleTokens get currentStyle => _styles[_current]!;

  /// Read which enum is active (useful for radio buttons)
  AppTheme get current => _current;

  /// Change theme and notify listeners (also updates kStyle for legacy code)
  void setTheme(AppTheme theme) {
    if (_current == theme) return;
    _current = theme;
    kStyle = _styles[theme]!;
    notifyListeners();
  }

  /// Optional helper if you ever need names in UI
  String get currentName {
    switch (_current) {
      case AppTheme.darkForge:
        return 'Dark Forge';
      case AppTheme.silverGrove:
        return 'Silver Grove';
      case AppTheme.ironKeep:
        return 'Iron Keep (Solid)';
    }
  }
}
