import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roots_app/modules/map/constants/tier1_map.dart';
import 'package:roots_app/modules/map/constants/terrain_definitions.dart';
import 'package:roots_app/modules/map/services/map_data_loader.dart';
import 'package:roots_app/modules/map/models/enriched_tile_data.dart';
import 'package:roots_app/modules/map/widgets/map_painter.dart';
import 'package:roots_app/modules/map/widgets/tile_info_popup.dart';

class WorldMapScreen extends StatefulWidget {
  const WorldMapScreen({super.key});

  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen> {
  Offset _offset = Offset.zero;
  double _scale = 1.0;
  Offset? _initialFocalPoint;
  Offset _initialOffset = Offset.zero;
  double _initialScale = 1.0;

  List<EnrichedTileData> _tiles = [];
  EnrichedTileData? _selectedTile;

  late int minX, maxX, minY, maxY;

  @override
  void initState() {
    super.initState();
    _computeMapBounds();
    _loadMapData();
  }

  void _computeMapBounds() {
    final keys = tier1Map.keys;
    final coords = keys.map((k) => k.split('_').map(int.parse).toList()).toList();
    minX = coords.map((c) => c[0]).reduce(min);
    maxX = coords.map((c) => c[0]).reduce(max);
    minY = coords.map((c) => c[1]).reduce(min);
    maxY = coords.map((c) => c[1]).reduce(max);
  }

  Future<void> _loadMapData() async {
    final enriched = await MapDataLoader.loadFullMapData();
    setState(() {
      _tiles = enriched;
    });
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _initialFocalPoint = details.focalPoint;
    _initialOffset = _offset;
    _initialScale = _scale;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    final delta = details.focalPoint - _initialFocalPoint!;
    setState(() {
      _scale = (_initialScale * details.scale).clamp(0.2, 4.0);
      _offset = _initialOffset + delta / _scale;
    });
  }

  void _handleScroll(PointerScrollEvent event) {
    const zoomStep = 0.1;
    final direction = event.scrollDelta.dy > 0 ? -1 : 1;
    final factor = 1 + zoomStep * direction;

    final mouseX = event.localPosition.dx;
    final mouseY = event.localPosition.dy;

    final worldX = (mouseX - _offset.dx) / _scale;
    final worldY = (mouseY - _offset.dy) / _scale;

    final newScale = (_scale * factor).clamp(0.2, 4.0);
    final newOffsetX = mouseX - worldX * newScale;
    final newOffsetY = mouseY - worldY * newScale;

    setState(() {
      _scale = newScale;
      _offset = Offset(newOffsetX, newOffsetY);
    });
  }

  void _handleTapUp(TapUpDetails details) {
    final local = details.localPosition;
    final worldX = (local.dx - _offset.dx) / _scale;
    final worldY = (local.dy - _offset.dy) / _scale;

    final tileX = (worldX / MapPainter.tileSize).floor() + minX;
    final tileY = (worldY / MapPainter.tileSize).floor() + minY;

    final tapped = _tiles.firstWhere(
          (t) => t.x == tileX && t.y == tileY,
      orElse: () => EnrichedTileData(tileKey: '', terrain: '', x: tileX, y: tileY),
    );

    setState(() {
      _selectedTile = tapped;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(title: const Text('🌍 World Map')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collectionGroup('heroGroups')
            .where('insideVillage', isEqualTo: false)
            .snapshots(),
        builder: (context, snapshot) {
          // 🔁 Copy the original _tiles list to update heroGroups
          final tilesWithLiveHeroes = _tiles.map((tile) {
            final matchingHeroes = snapshot.data?.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['tileX'] == tile.x && data['tileY'] == tile.y;
            }).map((doc) => doc.data() as Map<String, dynamic>).toList();

            return EnrichedTileData(
              tileKey: tile.tileKey,
              x: tile.x,
              y: tile.y,
              terrain: tile.terrain,
              villageId: tile.villageId,
              villageName: tile.villageName,
              ownerId: tile.ownerId,
              ownerName: tile.ownerName,
              guildId: tile.guildId,
              guildName: tile.guildName,
              guildTag: tile.guildTag,
              allianceId: tile.allianceId,
              allianceTag: tile.allianceTag,
              heroGroups: matchingHeroes ?? [],
            );
          }).toList();

          return Stack(
            children: [
              Listener(
                onPointerSignal: (event) {
                  if (event is PointerScrollEvent) _handleScroll(event);
                },
                child: GestureDetector(
                  onTapUp: _handleTapUp,
                  onScaleStart: _handleScaleStart,
                  onScaleUpdate: _handleScaleUpdate,
                  child: CustomPaint(
                    painter: MapPainter(
                      offset: _offset,
                      scale: _scale,
                      screenSize: MediaQuery.of(context).size,
                      minX: minX,
                      minY: minY,
                      tiles: tilesWithLiveHeroes,
                    ),
                    size: MediaQuery.of(context).size,
                  ),
                ),
              ),

              // 🪄 Tile Info Popup
              if (_selectedTile != null)
                Positioned(
                  top: 20,
                  left: (MediaQuery.of(context).size.width / 2) - 160,
                  child: SizedBox(
                    width: 320,
                    child: TileInfoPopup(
                      tile: _selectedTile!,
                      onClose: () => setState(() => _selectedTile = null),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}