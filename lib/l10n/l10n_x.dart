import 'package:flutter/widgets.dart';
import 'package:roots_app/l10n/gen/app_localizations.dart';

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
