import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roots_app/modules/map/providers/terrain_provider.dart';

class MapTileMiniMapWidget extends StatelessWidget {
  final int x;
  final int y;
  final String terrainId;

  /// When true, draws a subtle 1px grid/border around the tile.
  /// Set to false to remove visible lines between tiles.
  final bool drawGrid;

  const MapTileMiniMapWidget({
    super.key,
    required this.x,
    required this.y,
    required this.terrainId,
    this.drawGrid = true, // keep old behavior by default
  });

  @override
  Widget build(BuildContext context) {
    final terrain = context.watch<TerrainProvider>().getTerrainById(terrainId);
    final bgColor = terrain?.color ?? Colors.grey;
    final icon = terrain?.icon;

    return CustomPaint(
      painter: _MiniTilePainter(
        fillColor: bgColor,
        drawGrid: drawGrid,
      ),
      // Keep the icon as a child so it stays crisp & centered
      child: (icon != null && terrainId != 'water')
          ? Center(
        child: Icon(
          icon,
          size: 10,
          color: Colors.black87,
        ),
      )
          : const SizedBox.shrink(),
    );
  }
}

class _MiniTilePainter extends CustomPainter {
  final Color fillColor;
  final bool drawGrid;

  _MiniTilePainter({
    required this.fillColor,
    required this.drawGrid,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Snap to pixel grid to avoid hairline seams
    final w = size.width.ceilToDouble();
    final h = size.height.ceilToDouble();
    final rect = Rect.fromLTWH(0, 0, w, h);

    // Base fill (disable AA & filtering for hard edges)
    final fill = Paint()
      ..isAntiAlias = false
      ..filterQuality = FilterQuality.none
      ..color = fillColor;
    canvas.drawRect(rect, fill);

    // Optional border/grid
    if (drawGrid) {
      final grid = Paint()
        ..isAntiAlias = false
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = Colors.black.withAlpha(15); // ~6% opacity
      canvas.drawRect(rect, grid);
    }
  }

  @override
  bool shouldRepaint(covariant _MiniTilePainter oldDelegate) {
    return fillColor != oldDelegate.fillColor || drawGrid != oldDelegate.drawGrid;
  }
}
