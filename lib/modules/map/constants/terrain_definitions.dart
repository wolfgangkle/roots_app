import 'package:flutter/material.dart';
import 'package:roots_app/modules/map/models/terrain_type_model.dart';

const Map<String, TerrainTypeModel> terrainDefinitions = {
  'plains': TerrainTypeModel(
    id: 'plains',
    name: 'Plains',
    color: Color(0xFFA5D6A7), // unified green
    icon: null,
    walkable: true,
  ),
  'forest': TerrainTypeModel(
    id: 'forest',
    name: 'Forest',
    color: Color(0xFFA5D6A7), // same green
    icon: Icons.park,
    walkable: true,
  ),
  'swamp': TerrainTypeModel(
    id: 'swamp',
    name: 'Swamp',
    color: Color(0xFFA5D6A7), // same green
    icon: Icons.grass,
    walkable: true,
  ),
  'snow': TerrainTypeModel(
    id: 'snow',
    name: 'Snow',
    color: Color(0xFFE1F5FE), // whiteish
    icon: Icons.ac_unit,
    walkable: true,
  ),
  'tundra': TerrainTypeModel(
    id: 'tundra',
    name: 'Tundra',
    color: Color(0xFFA5D6A7), // same green
    icon: Icons.landscape,
    walkable: true,
  ),
  'water': TerrainTypeModel(
    id: 'water',
    name: 'Water',
    color: Color(0xFF81D4FA), // blue
    icon: Icons.water,
    walkable: false,
  ),
  'mountain': TerrainTypeModel(
    id: 'mountain',
    name: 'Mountain',
    color: Color(0xFFB0BEC5), // gray
    icon: Icons.terrain,
    walkable: false,
  ),
};
