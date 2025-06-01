import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:roots_app/modules/heroes/models/hero_group_model.dart';
import 'package:roots_app/modules/map/constants/tier1_map.dart';
import 'package:roots_app/modules/map/widgets/map_tile_widget.dart';

class HeroGroupMovementMiniMap extends StatefulWidget {
  final HeroGroupModel group;

  const HeroGroupMovementMiniMap({
    super.key,
    required this.group,
  });

  @override
  State<HeroGroupMovementMiniMap> createState() => _HeroGroupMovementMiniMapState();
}

class _HeroGroupMovementMiniMapState extends State<HeroGroupMovementMiniMap> {
  static const int mapSize = 100;
  static const int visibleTiles = 20;

  late Offset panOffset;
  Offset? dragStart;

  Set<String> villageTiles = {};

  @override
  void initState() {
    super.initState();

    // Start centered on hero group
    panOffset = Offset(
      (widget.group.tileX - visibleTiles ~/ 2).toDouble(),
      (widget.group.tileY - visibleTiles ~/ 2).toDouble(),
    );

    _fetchVillageTiles();
  }

  Future<void> _fetchVillageTiles() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('mapTiles')
        .where('villageId', isGreaterThan: '')
        .get();

    setState(() {
      villageTiles = snapshot.docs.map((doc) => doc.id).toSet();
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxSize = constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth
            : constraints.maxHeight;

        final tileSize = (maxSize / visibleTiles).clamp(16.0, 32.0);
        final mapSizePx = tileSize * visibleTiles;

        return GestureDetector(
          onPanStart: (details) => dragStart = details.localPosition,
          onPanUpdate: (details) {
            final delta = details.localPosition - dragStart!;
            dragStart = details.localPosition;

            final dx = (panOffset.dx - delta.dx / tileSize)
                .clamp(0, mapSize - visibleTiles);
            final dy = (panOffset.dy - delta.dy / tileSize)
                .clamp(0, mapSize - visibleTiles);

            setState(() {
              panOffset = Offset(dx.toDouble(), dy.toDouble());
            });
          },
          onPanEnd: (_) => dragStart = null,
          child: Center(
            child: SizedBox(
              width: mapSizePx,
              height: mapSizePx,
              child: Stack(
                children: [
                  Container(color: const Color(0xFFA5D6A7)),
                  GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: visibleTiles,
                      childAspectRatio: 1,
                    ),
                    itemCount: visibleTiles * visibleTiles,
                    itemBuilder: (context, index) {
                      final x = panOffset.dx.toInt() + (index % visibleTiles);
                      final y = panOffset.dy.toInt() + (index ~/ visibleTiles);
                      final tileKey = '${x}_$y';
                      final terrainId = tier1Map[tileKey] ?? 'plains';
                      final isHero = (x == widget.group.tileX && y == widget.group.tileY);
                      final isWaypoint = (widget.group.movementQueue ?? [])
                          .any((wp) => wp['x'] == x && wp['y'] == y);
                      final hasVillage = villageTiles.contains(tileKey);

                      return Stack(
                        children: [
                          MapTileWidget(x: x, y: y, terrainId: terrainId),
                          if (hasVillage)
                            const Center(
                                child: Text("🏰", style: TextStyle(fontSize: 16))),
                          if (isHero)
                            const Center(
                                child: Text("🧙", style: TextStyle(fontSize: 16))),
                          if (isWaypoint)
                            const Center(
                                child: Icon(Icons.circle,
                                    size: 10, color: Colors.orange)),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
