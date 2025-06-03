import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roots_app/modules/map/models/enriched_tile_data.dart';
import 'package:roots_app/modules/profile/views/player_profile_screen.dart';
import 'package:roots_app/modules/profile/views/guild_profile_screen.dart';
import 'package:roots_app/modules/profile/views/alliance_profile_screen.dart';
import 'package:roots_app/screens/controllers/main_content_controller.dart';

class MinimapTileInfoPopup extends StatelessWidget {
  final EnrichedTileData tile;
  final VoidCallback onClose;

  const MinimapTileInfoPopup({
    super.key,
    required this.tile,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<MainContentController>(context, listen: false);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 📍 Tile coords
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tile: (${tile.x}, ${tile.y})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: onClose,
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 🌄 Terrain
        Row(
          children: [
            const Icon(Icons.landscape, size: 16),
            const SizedBox(width: 6),
            Text(tile.terrain.toUpperCase()),
          ],
        ),

        if (tile.villageId != null) ...[
          const Divider(height: 16),

          // 🏰 Village name
          Row(
            children: [
              const Text('🏰', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                tile.villageName ?? 'Unnamed Village',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),

          const SizedBox(height: 6),

          // 🧑‍✈️ Owner info
          Row(
            children: [
              if (tile.allianceTag != null && tile.allianceId != null)
                InkWell(
                  onTap: () => controller.setCustomContent(
                    AllianceProfileScreen(allianceId: tile.allianceId!),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      '[${tile.allianceTag}]',
                      style: const TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              if (tile.guildTag != null && tile.guildId != null)
                InkWell(
                  onTap: () => controller.setCustomContent(
                    GuildProfileScreen(guildId: tile.guildId!),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      '[${tile.guildTag}]',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              if (tile.ownerId != null && tile.ownerName != null)
                InkWell(
                  onTap: () => controller.setCustomContent(
                    PlayerProfileScreen(userId: tile.ownerId!),
                  ),
                  child: Text(
                    tile.ownerName!,
                    style: const TextStyle(
                      decoration: TextDecoration.underline,
                      color: Colors.black87,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}