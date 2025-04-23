import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:roots_app/modules/village/data/items.dart';

class HeroBackpackList extends StatefulWidget {
  final String heroId;
  final int tileX;
  final int tileY;
  final String? villageId;
  final bool insideVillage;

  const HeroBackpackList({
    super.key,
    required this.heroId,
    required this.tileX,
    required this.tileY,
    required this.villageId,
    required this.insideVillage,
  });

  @override
  State<HeroBackpackList> createState() => _HeroBackpackListState();
}

class _HeroBackpackListState extends State<HeroBackpackList> {
  bool _isLoading = false;
  int? _activeIndex;

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return const Center(child: Text("⚠️ Not logged in."));
    }

    final heroRef = FirebaseFirestore.instance.collection('heroes').doc(widget.heroId);

    return StreamBuilder<DocumentSnapshot>(
      stream: heroRef.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text("🚫 Hero not found."));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final backpack = List<Map<String, dynamic>>.from(data['backpack'] ?? []);

        if (backpack.isEmpty) {
          return const Center(child: Text("🎒 Backpack is empty."));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text('🎒 Backpack', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: backpack.length,
              itemBuilder: (context, index) {
                final item = backpack[index];
                final itemId = item['itemId'];
                final quantity = item['quantity'] ?? 1;
                final meta = gameItems[itemId] ?? {};
                final stats = item['craftedStats'] as Map<String, dynamic>? ?? {};
                final itemName = meta['name'] ?? itemId;
                final slot = _determineEquipSlot(meta);

                final isThisActive = _activeIndex == index && _isLoading;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text("$itemName ×$quantity"),
                    subtitle: stats.isNotEmpty
                        ? Text(stats.entries.map((e) => "${e.key}: ${e.value}").join(' • '))
                        : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Equip',
                          icon: isThisActive
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : const Icon(Icons.check),
                          onPressed: _isLoading
                              ? null
                              : () async {
                            setState(() {
                              _isLoading = true;
                              _activeIndex = index;
                            });
                            try {
                              final callable = FirebaseFunctions.instance.httpsCallable('equipItemFromBackpack');
                              final result = await callable.call({
                                'heroId': widget.heroId,
                                'backpackIndex': index,
                                'slot': slot,
                              });

                              if (context.mounted) {
                                final stats = result.data['updatedStats'];
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "🛡 Equipped to $slot\nAtk: ${stats['attackMin']}-${stats['attackMax']}, Def: ${stats['defense']}",
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("❌ Failed to equip: $e")),
                                );
                              }
                            } finally {
                              if (mounted) {
                                setState(() {
                                  _isLoading = false;
                                  _activeIndex = null;
                                });
                              }
                            }
                          },
                        ),
                        IconButton(
                          tooltip: 'Drop',
                          icon: isThisActive
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : const Icon(Icons.backspace),
                          onPressed: _isLoading
                              ? null
                              : () async {
                            setState(() {
                              _isLoading = true;
                              _activeIndex = index;
                            });
                            try {
                              final callable = FirebaseFunctions.instance.httpsCallable('dropHeroItem');
                              final result = await callable.call({
                                'heroId': widget.heroId,
                                'backpackIndex': index,
                                'quantity': 1,
                                if (widget.insideVillage) 'villageId': widget.villageId,
                                if (!widget.insideVillage) 'tileKey': '${widget.tileX}_${widget.tileY}',
                              });

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("📦 Dropped ${result.data['quantity']}x ${result.data['itemId']}"),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("❌ Failed to drop item: $e")),
                                );
                              }
                            } finally {
                              if (mounted) {
                                setState(() {
                                  _isLoading = false;
                                  _activeIndex = null;
                                });
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  String _determineEquipSlot(Map<String, dynamic> meta) {
    final raw = meta['equipSlot']?.toString().toLowerCase() ?? 'main_hand';
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
