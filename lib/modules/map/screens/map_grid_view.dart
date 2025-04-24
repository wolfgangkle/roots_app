import 'package:flutter/material.dart';
import 'package:roots_app/modules/map/constants/tier1_map.dart';
import 'package:roots_app/modules/map/widgets/map_tile_widget.dart';

class MapGridView extends StatefulWidget {
  const MapGridView({super.key});

  @override
  State<MapGridView> createState() => _MapGridViewState();
}

class _MapGridViewState extends State<MapGridView> {
  static const int mapSize = 100;
  static const int tileSize = 24;
  static const int visibleTiles = 20;

  Offset panOffset = const Offset(40, 40); // tile coordinates
  Offset? dragStart;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        dragStart = details.localPosition;
      },
      onPanUpdate: (details) {
        final dragDelta = details.localPosition - dragStart!;
        dragStart = details.localPosition;

        final dx = (panOffset.dx - dragDelta.dx / tileSize).clamp(0, mapSize - visibleTiles);
        final dy = (panOffset.dy - dragDelta.dy / tileSize).clamp(0, mapSize - visibleTiles);

        setState(() {
          panOffset = Offset(dx.toDouble(), dy.toDouble());
        });
      },
      onPanEnd: (_) => dragStart = null,
      child: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: visibleTiles * tileSize.toDouble(),
          height: visibleTiles * tileSize.toDouble(),
          child: Column(
            children: List.generate(visibleTiles, (dy) {
              final y = panOffset.dy.toInt() + dy;
              return Row(
                children: List.generate(visibleTiles, (dx) {
                  final x = panOffset.dx.toInt() + dx;
                  if (x >= mapSize || y >= mapSize) {
                    return SizedBox(width: tileSize.toDouble(), height: tileSize.toDouble());
                  }
                  final terrainId = tier1Map['${x}_$y'] ?? 'plains';
                  return SizedBox(
                    width: tileSize.toDouble(),
                    height: tileSize.toDouble(),
                    child: MapTileWidget(
                      x: x,
                      y: y,
                      terrainId: terrainId,
                    ),
                  );
                }),
              );
            }),
          ),
        ),
      ),
    );
  }
}
