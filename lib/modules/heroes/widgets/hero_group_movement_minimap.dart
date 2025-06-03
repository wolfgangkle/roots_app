import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:roots_app/modules/heroes/models/hero_group_model.dart';
import 'package:roots_app/modules/map/constants/tier1_map.dart';
import 'package:roots_app/modules/map/models/enriched_tile_data.dart';
import 'package:roots_app/modules/map/services/map_data_loader.dart';
import 'package:roots_app/modules/map/widgets/map_tile_minimap_widget.dart';
import 'package:roots_app/modules/map/widgets/minimap_tile_info_popup.dart';

class HeroGroupMovementMiniMap extends StatefulWidget {
  final HeroGroupModel group;
  final List<Map<String, dynamic>> waypoints;

  const HeroGroupMovementMiniMap({
    super.key,
    required this.group,
    this.waypoints = const [],
  });

  @override
  State<HeroGroupMovementMiniMap> createState() => HeroGroupMovementMiniMapState();
}

class HeroGroupMovementMiniMapState extends State<HeroGroupMovementMiniMap> {
  static const int visibleTiles = 20;

  late Offset panOffset;
  Offset? dragStart;

  late int minX, maxX, minY, maxY;
  Set<String> villageTiles = {};
  EnrichedTileData? selectedTile;
  List<EnrichedTileData> allTiles = [];

  @override
  void initState() {
    super.initState();
    _computeMapBounds();

    panOffset = Offset(
      (widget.group.tileX - visibleTiles ~/ 2).toDouble(),
      (widget.group.tileY - visibleTiles ~/ 2).toDouble(),
    );

    _fetchData();
  }

  void _computeMapBounds() {
    final coords = tier1Map.keys.map((k) {
      final parts = k.split('_');
      return [int.parse(parts[0]), int.parse(parts[1])];
    }).toList();

    minX = coords.map((c) => c[0]).reduce(min);
    maxX = coords.map((c) => c[0]).reduce(max);
    minY = coords.map((c) => c[1]).reduce(min);
    maxY = coords.map((c) => c[1]).reduce(max);
  }

  Future<void> _fetchData() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('mapTiles')
        .where('villageId', isGreaterThan: '')
        .get();

    final enriched = await MapDataLoader.loadFullMapData();

    setState(() {
      villageTiles = snapshot.docs.map((doc) => doc.id).toSet();
      allTiles = enriched;
    });
  }

  void _showTileInfo(int x, int y) {
    final match = allTiles.firstWhere(
          (t) => t.x == x && t.y == y,
      orElse: () => EnrichedTileData(
        tileKey: '${x}_$y',
        x: x,
        y: y,
        terrain: tier1Map['${x}_$y'] ?? 'plains',
      ),
    );

    setState(() {
      selectedTile = match;
    });
  }

  void centerOnTile(int x, int y) {
    setState(() {
      panOffset = Offset(
        (x - visibleTiles ~/ 2).toDouble(),
        (y - visibleTiles ~/ 2).toDouble(),
      );
    });
  }


  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxSize = constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth
            : constraints.maxHeight;

        final tileSize = (maxSize / visibleTiles).floorToDouble();
        final mapSizePx = tileSize * visibleTiles;

        return Stack(
          alignment: Alignment.topCenter,
          children: [
            GestureDetector(
              onPanStart: (details) => dragStart = details.localPosition,
              onPanUpdate: (details) {
                final delta = details.localPosition - dragStart!;
                dragStart = details.localPosition;

                final dx = (panOffset.dx - delta.dx / tileSize)
                    .clamp(minX.toDouble(), maxX - visibleTiles + 1);
                final dy = (panOffset.dy - delta.dy / tileSize)
                    .clamp(minY.toDouble(), maxY - visibleTiles + 1);

                setState(() {
                  panOffset = Offset(dx.toDouble(), dy.toDouble());
                });
              },
              onPanEnd: (_) {
                dragStart = null;
                setState(() {
                  panOffset = Offset(
                    panOffset.dx.roundToDouble(),
                    panOffset.dy.roundToDouble(),
                  );
                });
              },
              child: Center(
                child: Container(
                  width: mapSizePx,
                  height: mapSizePx,
                  color: const Color(0xFFA5D6A7),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: visibleTiles,
                      childAspectRatio: 1,
                      mainAxisSpacing: 0,
                      crossAxisSpacing: 0,
                    ),
                    itemCount: visibleTiles * visibleTiles,
                    itemBuilder: (context, index) {
                      final x = panOffset.dx.floor() + (index % visibleTiles);
                      final y = panOffset.dy.floor() + (index ~/ visibleTiles);
                      final tileKey = '${x}_$y';
                      final terrainId = tier1Map[tileKey] ?? 'plains';

                      final isHero = (x == widget.group.tileX && y == widget.group.tileY);
                      final isNewWaypoint = widget.waypoints
                          .any((wp) => wp['x'] == x && wp['y'] == y);
                      final isSavedWaypoint = (widget.group.movementQueue ?? [])
                          .any((wp) => wp['x'] == x && wp['y'] == y);
                      final hasVillage = villageTiles.contains(tileKey);

                      return GestureDetector(
                        onTap: () => _showTileInfo(x, y),
                        child: Stack(
                          children: [
                            MapTileMiniMapWidget(
                              x: x,
                              y: y,
                              terrainId: terrainId,
                            ),
                            if (hasVillage)
                              const Center(child: Text("🏰", style: TextStyle(fontSize: 16))),
                            if (isHero)
                              const Center(child: Text("🧙", style: TextStyle(fontSize: 16))),
                            if (isNewWaypoint)
                              const Center(child: Icon(Icons.circle, size: 10, color: Colors.orange)),
                            if (!isNewWaypoint && isSavedWaypoint)
                              const Center(child: Icon(Icons.circle, size: 10, color: Colors.blue)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            if (selectedTile != null)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black26)],
                ),
                width: 320,
                child: MinimapTileInfoPopup(
                  tile: selectedTile!,
                  onClose: () => setState(() => selectedTile = null),
                ),
              ),
          ],
        );
      },
    );
  }
}

