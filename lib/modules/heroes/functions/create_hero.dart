import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart'; // ✅ for kDebugMode and debugPrint

/// Calls the Firebase Cloud Function `createHero` to create the main hero (mage).
///
/// Returns the heroId if creation succeeded, or `null` if there was an error.
Future<String?> createHero({
  required String heroName,
  required String race,
  required int tileX,
  required int tileY,
}) async {
  final functions = FirebaseFunctions.instance;
  final callable = functions.httpsCallable('createHero');

  try {
    final result = await callable.call({
      'heroName': heroName,
      'race': race,
      'tileX': tileX,
      'tileY': tileY,
    });

    final data = result.data as Map<String, dynamic>;
    return data['heroId'] as String?;
  } on FirebaseFunctionsException catch (e) {
    if (kDebugMode) {
      debugPrint('🔥 FirebaseFunctionsException: ${e.code} - ${e.message}');
    }
    return null;
  } catch (e) {
    if (kDebugMode) {
      debugPrint('🔥 Unexpected error calling createHero: $e');
    }
    return null;
  }
}
