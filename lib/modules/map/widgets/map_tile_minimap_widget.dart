import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roots_app/modules/map/providers/terrain_provider.dart';

class MapTileMiniMapWidget extends StatelessWidget {
  final int x;
  final int y;
  final String terrainId;

  const MapTileMiniMapWidget({
    super.key,
    required this.x,
    required this.y,
    required this.terrainId,
  });

  @override
  Widget build(BuildContext context) {
    final terrain = context.watch<TerrainProvider>().getTerrainById(terrainId);
    final bgColor = terrain?.color ?? Colors.grey;
    final icon = terrain?.icon;

    return Container(
      color: bgColor,
      alignment: Alignment.center,
      child: (icon != null && terrainId != 'water')
          ? Icon(icon, size: 10, color: Colors.black87)
          : null,
    );
  }
}
