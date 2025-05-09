import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart'; // Required for debugPrint

Future<bool> startHeroMovements({
  required String heroId,
  required int destinationX,
  required int destinationY,
  required List<Map<String, dynamic>> movementQueue,
}) async {
  try {
    final callable =
    FirebaseFunctions.instance.httpsCallable('startHeroMovementsFunction');
    final result = await callable.call({
      'heroId': heroId,
      'destinationX': destinationX,
      'destinationY': destinationY,
      'movementQueue': movementQueue,
    });

    return result.data['success'] == true;
  } catch (e) {
    debugPrint('🧨 startHeroMovements error: $e');
    return false;
  }
}
