import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/enriched_tile_data.dart';

class MapDataLoader {
  static Future<List<EnrichedTileData>> loadFullMapData() async {
    final db = FirebaseFirestore.instance;

    // 1. Load all mapTiles
    final tileSnapshot = await db.collection('mapTiles').get();
    final tiles = tileSnapshot.docs.map((doc) {
      final data = doc.data();
      final coords = doc.id.split('_').map(int.parse).toList();
      return {
        'tileKey': doc.id,
        'x': coords[0],
        'y': coords[1],
        'terrain': data['terrain'],
        'villageId': data['villageId'],
      };
    }).toList();

    // 2. Get all villageIds
    final villageIds = tiles
        .map((tile) => tile['villageId'])
        .whereType<String>()
        .toSet()
        .toList();

    // 3. Fetch all villages by ID using collectionGroup and filtering manually
    final villageDocs = <String, Map<String, dynamic>>{};
    if (villageIds.isNotEmpty) {
      final allVillageDocs = await db.collectionGroup('villages').get();
      for (var doc in allVillageDocs.docs) {
        if (villageIds.contains(doc.id)) {
          villageDocs[doc.id] = doc.data();
        }
      }
    }

    // 4. Fetch all owner profiles
    final ownerIds = villageDocs.values.map((v) => v['ownerId']).whereType<String>().toSet().toList();
    final profileDocs = <String, Map<String, dynamic>>{};

    if (ownerIds.isNotEmpty) {
      final batches = _splitIntoChunks(ownerIds, 10);

      for (final batch in batches) {
        for (final uid in batch) {
          final snap = await db.doc('users/$uid/profile/main').get();
          if (snap.exists) {
            profileDocs[uid] = snap.data()!;
          }
        }
      }
    }

    // 5. Fetch all heroGroups (those not inside villages)
    final heroSnapshot = await db.collectionGroup('heroGroups')
        .where('insideVillage', isEqualTo: false)
        .get();

    final heroGroupsByTile = <String, List<Map<String, dynamic>>>{};
    for (final doc in heroSnapshot.docs) {
      final data = doc.data();
      final x = data['tileX'];
      final y = data['tileY'];
      if (x is int && y is int) {
        final key = '${x}_${y}';
        heroGroupsByTile.putIfAbsent(key, () => []).add(data);
      }
    }

    // 6. Merge everything into EnrichedTileData
    return tiles.map((tile) {
      final village = villageDocs[tile['villageId']];
      final owner = village != null ? profileDocs[village['ownerId']] : null;
      final heroGroups = heroGroupsByTile[tile['tileKey']] ?? [];

      return EnrichedTileData(
        tileKey: tile['tileKey'],
        x: tile['x'],
        y: tile['y'],
        terrain: tile['terrain'],
        villageId: village != null ? tile['villageId'] : null,
        villageName: village?['name'],
        ownerId: village?['ownerId'],
        ownerName: owner?['heroName'] ?? owner?['displayName'],
        guildId: owner?['guildId'],
        guildName: owner?['guildName'],
        guildTag: owner?['guildTag'],
        allianceId: owner?['allianceId'],
        allianceTag: owner?['allianceTag'],
        heroGroups: heroGroups,
      );
    }).toList();
  }

  static List<List<T>> _splitIntoChunks<T>(List<T> list, int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < list.length; i += size) {
      chunks.add(list.sublist(i, i + size > list.length ? list.length : i + size));
    }
    return chunks;
  }
}
