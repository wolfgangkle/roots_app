// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settings_title => 'Settings';

  @override
  String get settings_appStyle => 'App Style';

  @override
  String get settings_appStyle_sub => 'Choose your UI theme';

  @override
  String get theme_darkForge => 'Dark Forge';

  @override
  String get theme_darkForge_sub => 'Dark, moody, glassy';

  @override
  String get theme_silverGrove => 'Silver Grove';

  @override
  String get theme_silverGrove_sub => 'Bright, frosted, bluish accent';

  @override
  String get theme_ironKeep => 'Iron Keep (Solid)';

  @override
  String get theme_ironKeep_sub => 'Opaque, medieval, non-glass';

  @override
  String get toggle_chatOverlay => 'Show Global Chat Overlay';

  @override
  String get settings_language => 'Language';

  @override
  String get settings_language_sub => 'Choose your language';

  @override
  String get lang_system => 'Use system language';

  @override
  String get lang_english => 'English';

  @override
  String get lang_german => 'Deutsch';
}
