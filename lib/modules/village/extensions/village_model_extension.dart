import 'package:roots_app/modules/village/models/village_model.dart';

extension VillageModelExtension on VillageModel {
  Map<String, int> get simulatedResources {
    final now = DateTime.now();
    final elapsedMinutes = now.difference(lastUpdated).inMinutes;

    if (elapsedMinutes < 1) {
      return {
        'wood': wood,
        'stone': stone,
        'food': food,
        'iron': iron,
        'gold': gold,
      };
    }

    // ✅ Use backend-trusted production values from Firestore
    final productionPerHour = currentProductionPerHour;

    final elapsedHours = elapsedMinutes / 60.0;

    return {
      'wood': wood + (productionPerHour['wood']! * elapsedHours).floor(),
      'stone': stone + (productionPerHour['stone']! * elapsedHours).floor(),
      'food': food + (productionPerHour['food']! * elapsedHours).floor(),
      'iron': iron + (productionPerHour['iron']! * elapsedHours).floor(),
      'gold': gold + (productionPerHour['gold']! * elapsedHours).floor(),
    };
  }
}
