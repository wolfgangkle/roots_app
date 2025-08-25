import 'dart:math';
import 'package:flutter/material.dart';
import 'package:roots_app/modules/map/constants/terrain_definitions.dart';
import 'package:roots_app/modules/map/models/enriched_tile_data.dart';

class MapPainter extends CustomPainter {
  static const double tileSize = 24;
  final Offset offset;
  final double scale;
  final Size screenSize;
  final int minX;
  final int minY;
  final List<EnrichedTileData> tiles;
  final Map<String, List<Map<String, dynamic>>> liveHeroGroups;

  /// When true, draws grid lines between tiles. Set to `false` to hide lines.
  final bool drawGrid;

  static final Map<String, TextPainter> _iconPainterCache = {};

  MapPainter({
    required this.offset,
    required this.scale,
    required this.screenSize,
    required this.minX,
    required this.minY,
    required this.tiles,
    required this.liveHeroGroups,
    this.drawGrid = true, // ← default keeps old behavior; set false to hide
  });

  TextPainter _getCachedIconPainter(
      String char,
      double fontSize, {
        String? fontFamily,
        String? fontPackage,
      }) {
    final key = '$char-${fontSize.toStringAsFixed(1)}-$fontFamily';

    if (!_iconPainterCache.containsKey(key)) {
      final tp = TextPainter(
        text: TextSpan(
          text: char,
          style: TextStyle(
            fontSize: fontSize,
            fontFamily: fontFamily,
            package: fontPackage,
            color: Colors.black87,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      _iconPainterCache[key] = tp;
    }

    return _iconPainterCache[key]!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..isAntiAlias = false // ↓ helps avoid hairline seams between tiles
      ..filterQuality = FilterQuality.none;

    final fontSize = max(8.0, 12 * scale);
    final heroPainter = _getCachedIconPainter('🧙', fontSize);
    final castlePainter = _getCachedIconPainter('🏰', fontSize);

    // Draw tiles
    for (final tile in tiles) {
      final def = terrainDefinitions[tile.terrain];
      paint.color = def?.color ?? Colors.grey;

      // Snap to pixel grid to reduce gaps when scaling
      final left = (((tile.x - minX) * tileSize * scale) + offset.dx).floorToDouble();
      final top  = (((tile.y - minY) * tileSize * scale) + offset.dy).floorToDouble();
      final w    = (tileSize * scale).ceilToDouble();
      final h    = (tileSize * scale).ceilToDouble();

      final rect = Rect.fromLTWH(left, top, w, h);
      canvas.drawRect(rect, paint);

      // 🌱 Terrain icon
      if (tile.terrain != 'water' && def?.icon != null) {
        final terrainPainter = _getCachedIconPainter(
          String.fromCharCode(def!.icon!.codePoint),
          fontSize,
          fontFamily: def.icon!.fontFamily,
          fontPackage: def.icon!.fontPackage,
        );
        final cx = left + (w - terrainPainter.width) / 2;
        final cy = top + (h - terrainPainter.height) / 2;
        terrainPainter.paint(canvas, Offset(cx, cy));
      }

      // 🏰 Village
      if (tile.villageId != null) {
        final cx = left + (w - castlePainter.width) / 2;
        final cy = top + (h - castlePainter.height) / 2;
        castlePainter.paint(canvas, Offset(cx, cy));
      }

      // 🧙 Live Hero group
      final liveKey = '${tile.x}_${tile.y}';
      if (liveHeroGroups[liveKey]?.isNotEmpty ?? false) {
        final cx = left + (w - heroPainter.width) / 2;
        final cy = top + h - heroPainter.height;
        heroPainter.paint(canvas, Offset(cx, cy));
      }
    }

    // Optional grid overlay
    if (drawGrid) {
      final gridPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = Colors.black.withValues(alpha: 0.06)
        ..isAntiAlias = false;

      // Compute extents from tiles (in case not all tiles are loaded)
      int maxTileX = tiles.isEmpty ? minX : tiles.map((t) => t.x).reduce(max);
      int maxTileY = tiles.isEmpty ? minY : tiles.map((t) => t.y).reduce(max);

      final totalCols = (maxTileX - minX + 1);
      final totalRows = (maxTileY - minY + 1);

      // Vertical lines
      for (int c = 0; c <= totalCols; c++) {
        final x = (((c * tileSize) * scale) + offset.dx).floorToDouble();
        canvas.drawLine(
          Offset(x, offset.dy.floorToDouble()),
          Offset(x, (offset.dy + totalRows * tileSize * scale).ceilToDouble()),
          gridPaint,
        );
      }

      // Horizontal lines
      for (int r = 0; r <= totalRows; r++) {
        final y = (((r * tileSize) * scale) + offset.dy).floorToDouble();
        canvas.drawLine(
          Offset(offset.dx.floorToDouble(), y),
          Offset((offset.dx + totalCols * tileSize * scale).ceilToDouble(), y),
          gridPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant MapPainter oldDelegate) {
    return offset != oldDelegate.offset ||
        scale != oldDelegate.scale ||
        screenSize != oldDelegate.screenSize ||
        tiles != oldDelegate.tiles ||
        liveHeroGroups != oldDelegate.liveHeroGroups ||
        drawGrid != oldDelegate.drawGrid;
  }
}
