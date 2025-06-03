import 'package:flutter/material.dart';

class TerrainTypeModel {
  final String id;
  final String name;
  final Color color;
  final IconData? icon;
  final bool walkable;
  final double movementCost; // 🆕 Cost multiplier for movement

  const TerrainTypeModel({
    required this.id,
    required this.name,
    required this.color,
    this.icon,
    required this.walkable,
    this.movementCost = 1.0, // Default: normal terrain
  });
}
