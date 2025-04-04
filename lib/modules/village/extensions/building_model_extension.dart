import 'package:roots_app/modules/village/data/building_definitions.dart';
import 'package:roots_app/modules/village/models/building_model.dart';

extension BuildingModelExtension on BuildingModel {
  int get productionPerHour {
    final def = buildingDefinitions[type];
    return (def?.baseProductionPerHour ?? 0) * level;
  }
}
