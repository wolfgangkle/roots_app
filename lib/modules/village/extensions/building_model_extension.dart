import 'package:roots_app/modules/village/data/building_definitions.dart';
import 'package:roots_app/modules/village/models/building_model.dart';

extension BuildingModelExtension on BuildingModel {
  int get productionPerHour {
    final def = buildingDefinitions.firstWhere(
          (b) => b['type'] == type,
      orElse: () => {},
    );
    final base = def['baseProductionPerHour'] ?? 0;
    return (base is num ? base.toInt() : 0) * level;
  }
}
