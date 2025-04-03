import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:roots_app/modules/village/models/village_model.dart';
import 'package:roots_app/modules/village/services/village_service.dart';

class UpgradeTimer {
  final String villageId;
  final VillageService villageService;
  Timer? _timer;

  UpgradeTimer({required this.villageId, required this.villageService});

  /// Starts a periodic timer that checks for a finished upgrade every second.
  void start() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) async {
      try {
        // Fetch the latest village data.
        final village = await villageService.getVillage(villageId);

        // Check if there's a build job and if it's complete.
        if (village.currentBuildJob != null && village.currentBuildJob!.isComplete) {
          // Apply the pending upgrade.
          await villageService.applyPendingUpgradeIfNeeded(village);
          // Cancel the timer once the upgrade is processed.
          timer.cancel();
        }
      } catch (e) {
        // Handle errors appropriately.
        print('Error checking upgrade: $e');
      }
    });
  }

  /// Stops the timer if needed.
  void stop() {
    _timer?.cancel();
  }
}
