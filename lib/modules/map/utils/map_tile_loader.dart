import 'package:roots_app/modules/map/models/map_tile_model.dart';
import 'package:roots_app/modules/map/constants/tier1_map.dart'; // make sure this contains tier1Map

class MapTileLoader {
  /// Loads tiles from local tier1Map in a square radius around center tile
  static Future<List<MapTileModel>> loadTilesInArea({
    required int centerX,
    required int centerY,
    required int radius,
  }) async {
    final tiles = <MapTileModel>[];

    final startX = centerX - radius;
    final endX = centerX + radius;
    final startY = centerY - radius;
    final endY = centerY + radius;

    for (int x = startX; x <= endX; x++) {
      for (int y = startY; y <= endY; y++) {
        final id = '${x}_$y';
        final terrain = tier1Map[id] ?? 'plains';

        tiles.add(MapTileModel(
          x: x,
          y: y,
          terrainId: terrain,
        ));
      }
    }

    return tiles;
  }
}
