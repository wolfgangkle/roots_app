// lib/modules/heroes/functions/spend_attribute_points.dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// Spend unspent attribute points for a hero.
/// Backend: functions/src/heroes/spendAttributePoints.ts
///
/// `allocation` should contain positive deltas for any of:
///   strength, dexterity, intelligence, constitution
///
/// Example:
///   await spendAttributePoints(heroId, {'strength': 2, 'constitution': 1});
Future<void> spendAttributePoints(
    String heroId,
    Map<String, int> allocation,
    ) async {
  if (heroId.isEmpty) {
    throw ArgumentError('heroId must not be empty.');
  }
  if (allocation.isEmpty) {
    throw ArgumentError('allocation must not be empty.');
  }

  // Only allow known keys; keep positives only.
  const allowed = {
    'strength',
    'dexterity',
    'intelligence',
    'constitution',
  };

  final Map<String, int> cleaned = {};
  allocation.forEach((k, v) {
    if (allowed.contains(k) && v is int && v > 0) {
      cleaned[k] = v;
    }
  });

  if (cleaned.isEmpty) {
    throw ArgumentError('allocation has no positive values for known attributes.');
  }

  // Your CF expects: { heroId, allocate: { strength, dexterity, intelligence, constitution } }
  final payload = <String, dynamic>{
    'heroId': heroId,
    'allocate': cleaned, // 👈 long keys under "allocate" to match the CF
  };

  // If your function is deployed to a specific region, use instanceFor(region: '…')
  final functions = FirebaseFunctions.instance;
  final callable = functions.httpsCallable('spendAttributePoints');

  try {
    debugPrint('▶️ spendAttributePoints payload: $payload');
    final res = await callable.call(payload);
    debugPrint('✅ spendAttributePoints result: ${res.data}');

    final data = res.data;
    final ok = (data == true) ||
        (data is Map && (data['ok'] == true || data['success'] == true));
    if (!ok) {
      throw Exception('Unexpected response from spendAttributePoints: $data');
    }
  } on FirebaseFunctionsException catch (e) {
    final msg = e.message ?? 'Cloud Function failed';
    throw Exception('spendAttributePoints failed: ${e.code}: $msg');
  }
}
