import 'package:flutter/material.dart';
import 'package:roots_app/modules/map/constants/tier1_map.dart';
import 'package:roots_app/modules/map/widgets/map_tile_controls_widget.dart';

// 🔷 Tokens (used for consistency; no extra panel here)
import 'package:provider/provider.dart';
import 'package:roots_app/theme/app_style_manager.dart';

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
    // keep tokens reactive (even if we don't render a panel here)
    context.watch<StyleManager>();

    const gridSize = 3;
    const gap = 6.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        // pick a comfy max width for the grid content inside the outer panel
        final maxUsable = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 340.0;

        // clamp to a reasonable size so tiles are large enough to tap
        final targetWidth = maxUsable.clamp(240.0, 360.0);
        final tileSize = (targetWidth - (gap * (gridSize - 1))) / gridSize;
        final gridHeight = tileSize * gridSize + gap * (gridSize - 1);

        return Center(
          child: SizedBox(
            width: targetWidth,
            height: gridHeight,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: gridSize * gridSize,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: gridSize,
                mainAxisSpacing: gap,
                crossAxisSpacing: gap,
              ),
              itemBuilder: (context, index) {
                final dx = (index % gridSize) - 1;
                final dy = (index ~/ gridSize) - 1;
                final tileX = currentX + dx;
                final tileY = currentY + dy;
                final tileKey = '${tileX}_$tileY';

                final isCenter = dx == 0 && dy == 0;
                final terrainId = tier1Map[tileKey] ?? 'plains';
                final isWaypoint = waypoints.any(
                      (wp) => wp['x'] == tileX && wp['y'] == tileY,
                );
                final hasVillage = villageTiles.contains(tileKey);
                final isBlocked = terrainId == 'water' || terrainId == 'mountain';

                return SizedBox(
                  width: tileSize,
                  height: tileSize,
                  child: MapTileControlsWidget(
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
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
