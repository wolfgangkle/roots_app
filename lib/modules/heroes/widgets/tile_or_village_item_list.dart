import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:roots_app/modules/village/data/items.dart';

class TileOrVillageItemList extends StatefulWidget {
  final String heroId;
  final bool insideVillage;
  final int tileX;
  final int tileY;
  final String? villageId; // nullable when outside a village

  const TileOrVillageItemList({
    super.key,
    required this.heroId,
    required this.insideVillage,
    required this.tileX,
    required this.tileY,
    this.villageId,
  });

  @override
  State<TileOrVillageItemList> createState() => _TileOrVillageItemListState();
}

class _TileOrVillageItemListState extends State<TileOrVillageItemList> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return const Center(child: Text("⚠️ Not logged in."));
    }

    final tileKey = "${widget.tileX}_${widget.tileY}";

    final itemsRef = widget.insideVillage && widget.villageId != null
        ? FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('villages')
        .doc(widget.villageId!)
        .collection('items')
        : FirebaseFirestore.instance
        .collection('mapTiles')
        .doc(tileKey)
        .collection('items');

    return StreamBuilder<QuerySnapshot>(
      stream: itemsRef.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("📦 No items available to equip."));
        }

        final items = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          itemCount: items.length,
          itemBuilder: (context, index) {
            final doc = items[index];
            final data = doc.data() as Map<String, dynamic>;
            final itemId = data['itemId'];
            final itemMeta = gameItems[itemId] ?? {};
            final name = itemMeta['name'] ?? 'Unknown';
            final description = itemMeta['description'] ?? '';
            final craftedStats = data['craftedStats'] as Map<String, dynamic>? ?? {};
            final slot = _determineSlot(itemMeta);
            final slotName = slot[0].toUpperCase() + slot.substring(1);

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: Theme.of(context).textTheme.titleMedium),
                    if (description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(description, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                      ),
                    if (craftedStats.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          craftedStats.entries.map((e) => "• ${e.key}: ${e.value}").join('\n'),
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.check),
                          label: Text("Equip to $slotName"),
                          onPressed: isLoading
                              ? null
                              : () async {
                            setState(() => isLoading = true);
                            try {
                              final callable = FirebaseFunctions.instance.httpsCallable('equipHeroItem');
                              final result = await callable.call({
                                'heroId': widget.heroId,
                                'itemDocId': doc.id,
                                'slot': slot,
                                if (widget.insideVillage) 'villageId': widget.villageId,
                                if (!widget.insideVillage) 'tileKey': tileKey,
                              });

                              final stats = result.data['updatedStats'];
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('✅ Equipped to $slotName (Atk: ${stats['attackMin']}–${stats['attackMax']}, Def: ${stats['defense']})')),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('⚠️ Failed to equip: $e')),
                                );
                              }
                            }
                            if (mounted) setState(() => isLoading = false);
                          },
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.backpack),
                          label: const Text("Backpack"),
                          onPressed: isLoading
                              ? null
                              : () async {
                            setState(() => isLoading = true);
                            try {
                              final callable = FirebaseFunctions.instance.httpsCallable('storeItemInBackpack');
                              await callable.call({
                                'heroId': widget.heroId,
                                'itemDocId': doc.id,
                                if (widget.insideVillage) 'villageId': widget.villageId,
                                if (!widget.insideVillage) 'tileKey': tileKey,
                              });

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("🎒 Moved to backpack")),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('❌ Failed to store: $e')),
                                );
                              }
                            }
                            if (mounted) setState(() => isLoading = false);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _determineSlot(Map<String, dynamic> itemMeta) {
    final slot = itemMeta['equipSlot']?.toString().toLowerCase() ?? 'main_hand';
    return _normalizeSlotName(slot);
  }

  String _normalizeSlotName(String raw) {
    switch (raw) {
      case 'main_hand':
        return 'mainHand';
      case 'offhand':
        return 'offHand';
      case 'head':
        return 'helmet';
      case 'hands':
        return 'arms';
      case 'feet':
        return 'feet';
      default:
        return raw;
    }
  }
}
