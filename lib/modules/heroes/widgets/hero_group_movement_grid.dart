import 'package:flutter/material.dart';
import 'package:roots_app/modules/map/constants/tier1_map.dart';
import 'package:roots_app/modules/map/widgets/map_tile_controls_widget.dart';

class HeroGroupMovementGrid extends StatelessWidget {
  final int currentX;
  final int currentY;
  final bool insideVillage;
  final List<Map<String, dynamic>> waypoints;
  final void Function(int x, int y) onTapTile;
  final Set<String> villageTiles;

  const HeroGroupMovementGrid({
    super.key,
    required this.currentX,
    required this.currentY,
    required this.insideVillage,
    required this.waypoints,
    required this.onTapTile,
    required this.villageTiles,
  });

  @override
  Widget build(BuildContext context) {
    const gridSize = 3;
    const tileSize = 100.0;
    final gridDimension = tileSize * gridSize + 8;

    return Center(
      child: SizedBox(
        width: gridDimension,
        height: gridDimension,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: gridSize * gridSize,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: gridSize,
          ),
          itemBuilder: (context, index) {
            final dx = (index % gridSize) - 1;
            final dy = (index ~/ gridSize) - 1;
            final tileX = currentX + dx;
            final tileY = currentY + dy;
            final tileKey = '${tileX}_$tileY';

            final isCenter = dx == 0 && dy == 0;
            final terrainId = tier1Map[tileKey] ?? 'plains';
            final isWaypoint =
            waypoints.any((wp) => wp['x'] == tileX && wp['y'] == tileY);
            final hasVillage = villageTiles.contains(tileKey);
            final isBlocked = terrainId == 'water' || terrainId == 'mountain';

            return MapTileControlsWidget(
              x: tileX,
              y: tileY,
              terrainId: terrainId,
              showCoords: true,
              isCurrentTile: isCenter,
              hasVillage: hasVillage,
              isWaypoint: isWaypoint,
              isBlocked: isBlocked,
              onTap: isCenter || insideVillage || isBlocked
                  ? null
                  : () => onTapTile(tileX, tileY),
            );
          },
        ),
      ),
    );
  }
}
