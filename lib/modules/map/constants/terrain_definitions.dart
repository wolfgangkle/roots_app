import 'package:flutter/material.dart';
import 'package:roots_app/modules/map/models/terrain_type_model.dart';

const Map<String, TerrainTypeModel> terrainDefinitions = {
  'plains': TerrainTypeModel(
    id: 'plains',
    name: 'Plains',
    color: Color(0xFFA5D6A7),
    icon: null,
    walkable: true,
    movementCost: 1.0,
  ),
  'forest': TerrainTypeModel(
    id: 'forest',
    name: 'Forest',
    color: Color(0xFFA5D6A7),
    icon: Icons.park,
    walkable: true,
    movementCost: 1.5,
  ),
  'swamp': TerrainTypeModel(
    id: 'swamp',
    name: 'Swamp',
    color: Color(0xFFA5D6A7),
    icon: Icons.grass,
    walkable: true,
    movementCost: 2.0,
  ),
  'snow': TerrainTypeModel(
    id: 'snow',
    name: 'Snow',
    color: Color(0xFFE1F5FE),
    icon: Icons.ac_unit,
    walkable: true,
    movementCost: 1.8,
  ),
  'tundra': TerrainTypeModel(
    id: 'tundra',
    name: 'Tundra',
    color: Color(0xFFA5D6A7),
    icon: Icons.landscape,
    walkable: true,
    movementCost: 1.3,
  ),
  'water': TerrainTypeModel(
    id: 'water',
    name: 'Water',
    color: Color(0xFF81D4FA),
    icon: Icons.water,
    walkable: false,
    movementCost: 999.0, // unreachable
  ),
  'mountain': TerrainTypeModel(
    id: 'mountain',
    name: 'Mountain',
    color: Color(0xFFB0BEC5),
    icon: Icons.terrain,
    walkable: false,
    movementCost: 999.0, // unreachable
  ),
};

