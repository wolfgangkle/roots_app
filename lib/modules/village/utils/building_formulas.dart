/// 🔄 Upgrade duration formulas — matches Cloud Functions backend logic.
/// See: functions/src/utils/buildingFormulas.ts
library;

import 'dart:math';

/// Returns the upgrade duration based on building level.
/// Matches the backend logic: 30 * sqrt(level²) * 1000ms
Duration getUpgradeDuration(int level) {
  final milliseconds = 30 * sqrt(level * level) * 1000;
  return Duration(milliseconds: milliseconds.round());
}
