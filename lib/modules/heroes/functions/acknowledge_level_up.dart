// lib/modules/heroes/functions/acknowledge_level_up.dart
import 'package:cloud_functions/cloud_functions.dart';

/// Acknowledge a pending level-up for the given hero.
/// Backend: functions/src/heroes/acknowledgeLevelUp.ts
Future<void> acknowledgeLevelUp(String heroId) async {
  final callable =
  FirebaseFunctions.instance.httpsCallable('acknowledgeLevelUp');

  try {
    final res = await callable.call(<String, dynamic>{
      'heroId': heroId,
    });

    // Accept either `{ ok: true }` or a bare `true`.
    final data = res.data;
    final ok = (data == true) ||
        (data is Map && (data['ok'] == true || data['success'] == true));

    if (!ok) {
      throw Exception('Unexpected response from acknowledgeLevelUp: $data');
    }
  } on FirebaseFunctionsException catch (e) {
    // Surface a concise, user-meaningful message.
    final msg = e.message ?? 'Cloud Function failed';
    throw Exception('acknowledgeLevelUp failed: ${e.code}: $msg');
  } catch (e) {
    // Network or serialization errors
    rethrow;
  }
}
