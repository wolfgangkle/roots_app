import 'package:flutter/material.dart';
import 'package:roots_app/modules/map/models/enriched_tile_data.dart';
import 'package:roots_app/modules/profile/views/guild_profile_screen.dart';
import 'package:roots_app/modules/profile/views/alliance_profile_screen.dart';
import 'package:roots_app/modules/profile/views/player_profile_screen.dart';

class TileInfoPopup extends StatelessWidget {
  final EnrichedTileData tile;
  final VoidCallback onClose;
  final void Function(Widget widget)? onProfileTap;

  const TileInfoPopup({
    super.key,
    required this.tile,
    required this.onClose,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔘 Header Row
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

            // 🏞 Terrain
            Row(
              children: [
                const Icon(Icons.landscape, size: 18),
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

              // 🔗 Owner info with tags
              Row(
                children: [
                  if (tile.allianceTag != null && tile.allianceId != null)
                    InkWell(
                      onTap: () => onProfileTap?.call(
                        AllianceProfileScreen(allianceId: tile.allianceId!),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text(
                          '[${tile.allianceTag}]',
                          style: const TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  if (tile.guildTag != null && tile.guildId != null)
                    InkWell(
                      onTap: () => onProfileTap?.call(
                        GuildProfileScreen(guildId: tile.guildId!),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text(
                          '[${tile.guildTag}]',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  if (tile.ownerId != null)
                    InkWell(
                      onTap: () => onProfileTap?.call(
                        PlayerProfileScreen(userId: tile.ownerId!),
                      ),
                      child: Text(
                        tile.ownerName ?? 'Unknown',
                        style: const TextStyle(
                          decoration: TextDecoration.underline,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                ],
              ),
            ],

            if (tile.heroGroups.isNotEmpty) ...[
              const Divider(height: 16),
              Row(
                children: [
                  const Icon(Icons.group, size: 18),
                  const SizedBox(width: 6),
                  Text('${tile.heroGroups.length} hero group(s)'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
