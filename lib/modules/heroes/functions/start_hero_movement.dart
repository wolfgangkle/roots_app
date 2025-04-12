import 'package:cloud_functions/cloud_functions.dart';

Future<bool> startHeroMovements({
  required String heroId,
  required int destinationX,
  required int destinationY,
  required List<Map<String, int>> movementQueue,
}) async {
  try {
    final callable = FirebaseFunctions.instance.httpsCallable('startHeroMovementsFunction');
    final result = await callable.call({
      'heroId': heroId,
      'destinationX': destinationX,
      'destinationY': destinationY,
      'movementQueue': movementQueue,
    });

    return result.data['success'] == true;
  } catch (e) {
    print('🔥 Error starting hero movement: $e');
    return false;
  }
}
