import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roots_app/modules/map/providers/terrain_provider.dart';

class MapTileWidget extends StatelessWidget {
  final int x;
  final int y;
  final String terrainId;
  final bool showCoords;

  const MapTileWidget({
    super.key,
    required this.x,
    required this.y,
    required this.terrainId,
    this.showCoords = false,
  });

  @override
  Widget build(BuildContext context) {
    final terrain = context.watch<TerrainProvider>().getTerrainById(terrainId);

    final bgColor = terrain?.color ?? Colors.grey;
    final icon = terrain?.icon;

    return Container(
      color: bgColor,
      alignment: Alignment.center,
      child: icon != null
          ? Icon(icon, size: 16, color: Colors.black87)
          : showCoords
          ? Text(
        "($x,$y)",
        style: const TextStyle(fontSize: 8, color: Colors.black),
      )
          : null,
    );
  }
}
