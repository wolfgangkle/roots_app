import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:roots_app/modules/heroes/models/hero_model.dart';
import 'package:roots_app/modules/map/constants/tier1_map.dart';
import 'package:roots_app/modules/map/widgets/map_tile_widget.dart';

class HeroMiniMapOverlay extends StatefulWidget {
  final HeroModel hero;
  final List<Map<String, dynamic>> waypoints;
  final Offset centerTileOffset;

  const HeroMiniMapOverlay({
    super.key,
    required this.hero,
    required this.waypoints,
    required this.centerTileOffset,
  });

  @override
  State<HeroMiniMapOverlay> createState() => _HeroMiniMapOverlayState();
}

class _HeroMiniMapOverlayState extends State<HeroMiniMapOverlay> {
  static const int mapSize = 100;
  static const int visibleTiles = 20;

  late Offset panOffset;
  Offset? dragStart;

  Set<String> villageTiles = {};
  List<Map<String, dynamic>> nearbyHeroes = [];

  @override
  void initState() {
    super.initState();

    panOffset = widget.centerTileOffset;

    _fetchVillageTiles();
    _fetchNearbyHeroes();
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

  Future<void> _fetchNearbyHeroes() async {
    final radius = 5;
    final heroX = widget.hero.tileX;
    final heroY = widget.hero.tileY;

    final snapshot = await FirebaseFirestore.instance.collection('heroes').get();
    final others = snapshot.docs.where((doc) {
      final data = doc.data();
      if (doc.id == widget.hero.id) return false;

      final x = data['tileX'] ?? 0;
      final y = data['tileY'] ?? 0;
      final dx = (x - heroX).abs();
      final dy = (y - heroY).abs();
      return dx <= radius && dy <= radius;
    });

    setState(() {
      nearbyHeroes = others.map((doc) => {
        'id': doc.id,
        'tileX': doc['tileX'],
        'tileY': doc['tileY'],
      }).toList();
    });
  }

  bool isOtherHero(int x, int y) {
    return nearbyHeroes.any((hero) => hero['tileX'] == x && hero['tileY'] == y);
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

            final dx = (panOffset.dx - delta.dx / tileSize).clamp(0, mapSize - visibleTiles);
            final dy = (panOffset.dy - delta.dy / tileSize).clamp(0, mapSize - visibleTiles);

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
                      final tileKey = '${x}_${y}';
                      final terrainId = tier1Map[tileKey] ?? 'plains';
                      final isHero = (x == widget.hero.tileX && y == widget.hero.tileY);
                      final isWaypoint = widget.waypoints.any((wp) => wp['x'] == x && wp['y'] == y);
                      final hasVillage = villageTiles.contains(tileKey);
                      final isOther = isOtherHero(x, y);

                      return Stack(
                        children: [
                          MapTileWidget(x: x, y: y, terrainId: terrainId),
                          if (hasVillage)
                            const Center(child: Text("🏰", style: TextStyle(fontSize: 16))),
                          if (isOther)
                            const Center(child: Text("🗡️", style: TextStyle(fontSize: 16))),
                          if (isHero)
                            const Center(child: Text("🧙", style: TextStyle(fontSize: 16))),
                          if (isWaypoint)
                            const Center(child: Icon(Icons.circle, size: 10, color: Colors.orange)),
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
