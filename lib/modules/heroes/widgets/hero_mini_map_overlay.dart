import 'package:flutter/material.dart';
import 'package:roots_app/modules/heroes/models/hero_model.dart';
import 'package:roots_app/modules/map/constants/tier1_map.dart';
import 'package:roots_app/modules/map/widgets/map_tile_widget.dart';

class HeroMiniMapOverlay extends StatefulWidget {
  final HeroModel hero;
  final List<Offset> waypoints;

  const HeroMiniMapOverlay({
    super.key,
    required this.hero,
    required this.waypoints,
  });

  @override
  State<HeroMiniMapOverlay> createState() => _HeroMiniMapOverlayState();
}

class _HeroMiniMapOverlayState extends State<HeroMiniMapOverlay> {
  static const int mapSize = 100;
  static const int tileSize = 28;
  static const int visibleTiles = 20;

  late Offset panOffset;
  Offset? dragStart;

  @override
  void initState() {
    super.initState();
    // center on hero
    panOffset = Offset(
      (widget.hero.tileX - visibleTiles ~/ 2).clamp(0, mapSize - visibleTiles).toDouble(),
      (widget.hero.tileY - visibleTiles ~/ 2).clamp(0, mapSize - visibleTiles).toDouble(),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          width: visibleTiles * tileSize.toDouble(),
          height: visibleTiles * tileSize.toDouble(),
          child: Stack(
            children: [
              /// 🟩 Background "fill" layer to hide gaps
              Container(
                color: const Color(0xFFA5D6A7), // match walkable terrain bg
              ),

              /// 🧱 Tile Grid on top
              GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: visibleTiles,
                  mainAxisSpacing: 0,
                  crossAxisSpacing: 0,
                  childAspectRatio: 1,
                ),
                itemCount: visibleTiles * visibleTiles,
                itemBuilder: (context, index) {
                  final x = panOffset.dx.toInt() + (index % visibleTiles);
                  final y = panOffset.dy.toInt() + (index ~/ visibleTiles);
                  final terrainId = tier1Map['${x}_${y}'] ?? 'plains';
                  final isHero = (x == widget.hero.tileX && y == widget.hero.tileY);
                  final isWaypoint = widget.waypoints.contains(Offset(x.toDouble(), y.toDouble()));

                  return Stack(
                    children: [
                      MapTileWidget(x: x, y: y, terrainId: terrainId),
                      if (isHero)
                        const Center(
                          child: Text("🧙", style: TextStyle(fontSize: 16)),
                        ),
                      if (isWaypoint)
                        const Center(
                          child: Icon(Icons.circle, size: 10, color: Colors.orange),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
