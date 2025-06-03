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

  static final Map<String, TextPainter> _iconPainterCache = {};

  MapPainter({
    required this.offset,
    required this.scale,
    required this.screenSize,
    required this.minX,
    required this.minY,
    required this.tiles,
  });

  TextPainter _getCachedIconPainter(IconData icon, double fontSize) {
    final cacheKey = '${icon.codePoint}_${fontSize.toStringAsFixed(1)}';

    if (!_iconPainterCache.containsKey(cacheKey)) {
      final tp = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(icon.codePoint),
          style: TextStyle(
            fontFamily: icon.fontFamily,
            package: icon.fontPackage,
            fontSize: fontSize,
            color: Colors.black87,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      _iconPainterCache[cacheKey] = tp;
    }

    return _iconPainterCache[cacheKey]!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (final tile in tiles) {
      final def = terrainDefinitions[tile.terrain];
      paint.color = def?.color ?? Colors.grey;

      final left = (tile.x - minX) * tileSize * scale + offset.dx;
      final top = (tile.y - minY) * tileSize * scale + offset.dy;
      final rect = Rect.fromLTWH(left, top, tileSize * scale, tileSize * scale);
      canvas.drawRect(rect, paint);

      // 🌱 Terrain icon
      if (tile.terrain != 'water' && def?.icon != null) {
        final tp = _getCachedIconPainter(def!.icon!, max(8.0, 12 * scale));
        final centerX = left + (tileSize * scale - tp.width) / 2;
        final centerY = top + (tileSize * scale - tp.height) / 2;
        tp.paint(canvas, Offset(centerX, centerY));
      }

      // 🏰 Village icon
      if (tile.villageId != null) {
        final tp = TextPainter(
          text: TextSpan(
            text: '🏰',
            style: TextStyle(fontSize: max(8.0, 12 * scale)),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        final centerX = left + (tileSize * scale - tp.width) / 2;
        final centerY = top + (tileSize * scale - tp.height) / 2;
        tp.paint(canvas, Offset(centerX, centerY));
      }

      // 🧙 Hero group icon (if any)
      if (tile.heroGroups != null && tile.heroGroups!.isNotEmpty) {
        final tp = TextPainter(
          text: TextSpan(
            text: '🧙',
            style: TextStyle(fontSize: max(8.0, 12 * scale)),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        final centerX = left + (tileSize * scale - tp.width) / 2;
        final bottomY = top + (tileSize * scale) - tp.height;
        tp.paint(canvas, Offset(centerX, bottomY));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
