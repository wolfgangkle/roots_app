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

  static final Map<String, TextPainter> _iconPainterCache = {};

  MapPainter({
    required this.offset,
    required this.scale,
    required this.screenSize,
    required this.minX,
    required this.minY,
    required this.tiles,
    required this.liveHeroGroups,
  });

  TextPainter _getCachedIconPainter(String char, double fontSize, {String? fontFamily, String? fontPackage}) {
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
    final paint = Paint();
    final fontSize = max(8.0, 12 * scale);

    final heroPainter = _getCachedIconPainter('🧙', fontSize);
    final castlePainter = _getCachedIconPainter('🏰', fontSize);

    for (final tile in tiles) {
      final def = terrainDefinitions[tile.terrain];
      paint.color = def?.color ?? Colors.grey;

      final left = (tile.x - minX) * tileSize * scale + offset.dx;
      final top = (tile.y - minY) * tileSize * scale + offset.dy;
      final rect = Rect.fromLTWH(left, top, tileSize * scale, tileSize * scale);
      canvas.drawRect(rect, paint);

      // 🌱 Terrain icon
      if (tile.terrain != 'water' && def?.icon != null) {
        final terrainPainter = _getCachedIconPainter(
          String.fromCharCode(def!.icon!.codePoint),
          fontSize,
          fontFamily: def.icon!.fontFamily,
          fontPackage: def.icon!.fontPackage,
        );

        final cx = left + (tileSize * scale - terrainPainter.width) / 2;
        final cy = top + (tileSize * scale - terrainPainter.height) / 2;
        terrainPainter.paint(canvas, Offset(cx, cy));
      }

      // 🏰 Village
      if (tile.villageId != null) {
        final cx = left + (tileSize * scale - castlePainter.width) / 2;
        final cy = top + (tileSize * scale - castlePainter.height) / 2;
        castlePainter.paint(canvas, Offset(cx, cy));
      }

      // 🧙 Live Hero group
      final liveKey = '${tile.x}_${tile.y}';
      if (liveHeroGroups[liveKey]?.isNotEmpty ?? false) {
        final cx = left + (tileSize * scale - heroPainter.width) / 2;
        final cy = top + (tileSize * scale) - heroPainter.height;
        heroPainter.paint(canvas, Offset(cx, cy));
      }
    }
  }

  @override
  bool shouldRepaint(covariant MapPainter oldDelegate) {
    return offset != oldDelegate.offset ||
        scale != oldDelegate.scale ||
        screenSize != oldDelegate.screenSize ||
        tiles != oldDelegate.tiles ||
        liveHeroGroups != oldDelegate.liveHeroGroups;
  }
}
