import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roots_app/modules/map/providers/terrain_provider.dart';

class MapTileWidget extends StatelessWidget {
  final int x;
  final int y;
  final String terrainId;
  final bool showCoords;
  final bool small;

  final bool isCurrentTile;
  final bool isWaypoint;
  final bool hasVillage;
  final bool isBlocked;
  final VoidCallback? onTap;

  const MapTileWidget({
    super.key,
    required this.x,
    required this.y,
    required this.terrainId,
    this.showCoords = false,
    this.small = false,
    this.isCurrentTile = false,
    this.isWaypoint = false,
    this.hasVillage = false,
    this.isBlocked = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final terrain = context.watch<TerrainProvider>().getTerrainById(terrainId);
    final bgColor = terrain?.color ?? Colors.grey;
    final icon = terrain?.icon;

    final border = Border.all(
      color: isBlocked ? Colors.red : Colors.black87,
      width: isBlocked ? 2.5 : 1.0,
    );

    // ✅ Clean layout when small = true (for MiniMap)
    if (small) {
      return Container(
        color: bgColor,
        alignment: Alignment.center,
        child: icon != null
            ? Icon(icon, size: 10, color: Colors.black87)
            : null,
      );
    }

    // 🎯 Main Grid Tile (styled)
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(2), // Use internal padding
        decoration: BoxDecoration(
          color: bgColor,
          border: border,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Stack(
          children: [
            if (hasVillage)
              const Center(child: Text("🏰", style: TextStyle(fontSize: 16))),
            if (icon != null)
              Center(child: Icon(icon, size: 16, color: Colors.black87)),
            if (isCurrentTile)
              const Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: EdgeInsets.all(4),
                  child: Text("🧙", style: TextStyle(fontSize: 14)),
                ),
              ),
            if (isWaypoint)
              const Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.circle, size: 10, color: Colors.orange),
                ),
              ),
            if (showCoords)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    isCurrentTile ? 'You' : '($x,$y)',
                    style: const TextStyle(fontSize: 10, color: Colors.black),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
