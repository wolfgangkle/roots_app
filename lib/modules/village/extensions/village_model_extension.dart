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

    final elapsedHours = elapsedMinutes / 60.0;
    final productionPerHour = currentProductionPerHour;

    Map<String, int> result = {};

    for (final res in ['wood', 'stone', 'food', 'iron', 'gold']) {
      final base = getResource(res);
      final prod = productionPerHour[res] ?? 0;
      final gain = (prod * elapsedHours).floor();
      final capacity = storageCapacity[res] ?? double.infinity;

      int capped = base + gain;
      if (capped > capacity) capped = capacity.toInt();

      result[res] = capped;
    }

    return result;
  }

  int getResource(String key) {
    switch (key) {
      case 'wood':
        return wood;
      case 'stone':
        return stone;
      case 'food':
        return food;
      case 'iron':
        return iron;
      case 'gold':
        return gold;
      default:
        return 0;
    }
  }
}
