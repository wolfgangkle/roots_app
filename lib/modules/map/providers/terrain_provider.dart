import 'package:flutter/material.dart';
import 'package:roots_app/modules/map/models/terrain_type_model.dart';
import 'package:roots_app/modules/map/constants/terrain_definitions.dart';

class TerrainProvider extends ChangeNotifier {
  final Map<String, TerrainTypeModel> _terrainTypes = terrainDefinitions;
  bool _isLoaded = true;

  bool get isLoaded => _isLoaded;

  TerrainTypeModel? getTerrainById(String id) => _terrainTypes[id];

  List<TerrainTypeModel> get allTerrains => _terrainTypes.values.toList();
}
