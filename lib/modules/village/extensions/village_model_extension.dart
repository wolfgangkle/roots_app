import 'package:roots_app/modules/village/models/village_model.dart';
import 'package:roots_app/modules/village/extensions/building_model_extension.dart';

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

    final productionPerHour = {
      'wood': buildings['woodcutter']?.productionPerHour ?? 0,
      'stone': buildings['quarry']?.productionPerHour ?? 0,
      'food': buildings['farm']?.productionPerHour ?? 0,
      'iron': buildings['mine']?.productionPerHour ?? 0,
      'gold': buildings['goldmine']?.productionPerHour ?? 0,
    };

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
