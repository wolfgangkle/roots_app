import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:roots_app/modules/village/data/items.dart';

// 🔷 Tokens
import 'package:roots_app/theme/app_style_manager.dart';
import 'package:roots_app/theme/widgets/token_panels.dart';
import 'package:roots_app/theme/widgets/token_buttons.dart';
import 'package:provider/provider.dart';

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
  bool _isLoading = false;
  String? _activeDocId; // per-item spinner

  @override
  Widget build(BuildContext context) {
    // Live-reactive tokens
    context.watch<StyleManager>();
    final glass = kStyle.glass;
    final text = kStyle.textOnGlass;
    final buttons = kStyle.buttons;
    final cardPad = kStyle.card.padding;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return Center(
        child: Text("⚠️ Not logged in.", style: TextStyle(color: text.secondary)),
      );
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
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data!.docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              "📦 No items available to equip.",
              style: TextStyle(color: text.subtle),
            ),
          );
        }

        final items = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final doc = items[index];
            final data = doc.data() as Map<String, dynamic>;
            final itemId = data['itemId'];
            final itemMeta = gameItems[itemId] ?? {};
            final name = (itemMeta['name'] ?? 'Unknown').toString();
            final description = (itemMeta['description'] ?? '').toString();
            final craftedStats = data['craftedStats'] as Map<String, dynamic>? ?? {};
            final slot = _determineSlot(itemMeta);
            final slotName = slot.isNotEmpty ? slot[0].toUpperCase() + slot.substring(1) : 'Slot';

            final isActive = _isLoading && _activeDocId == doc.id;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: TokenPanel(
                glass: glass,
                text: text,
                padding: EdgeInsets.fromLTRB(
                  cardPad.left,
                  12,
                  cardPad.right,
                  12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + small meta
                    Text(
                      name,
                      style: TextStyle(
                        color: text.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(fontSize: 13, color: text.secondary),
                      ),
                    ],
                    if (craftedStats.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        craftedStats.entries
                            .map((e) => "• ${e.key}: ${e.value}")
                            .join('\n'),
                        style: TextStyle(fontSize: 12, color: text.subtle),
                      ),
                    ],
                    const SizedBox(height: 10),

                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Equip
                        TokenIconButton(
                          glass: glass,
                          text: text,
                          buttons: buttons,
                          variant: TokenButtonVariant.primary,
                          icon: isActive
                              ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : const Icon(Icons.check),
                          label: Text("Equip to $slotName"),
                          onPressed: isActive
                              ? null
                              : () async {
                            // ✅ Capture messenger BEFORE any await
                            final messenger = ScaffoldMessenger.of(context);

                            setState(() {
                              _isLoading = true;
                              _activeDocId = doc.id;
                            });
                            try {
                              final callable = FirebaseFunctions.instance
                                  .httpsCallable('equipHeroItem');
                              final result = await callable.call({
                                'heroId': widget.heroId,
                                'itemDocId': doc.id,
                                'slot': slot,
                                if (widget.insideVillage) 'villageId': widget.villageId,
                                if (!widget.insideVillage) 'tileKey': tileKey,
                              });

                              final stats = result.data['updatedStats'];
                              // ✅ Safe: using captured messenger (no context access after await)
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    stats != null
                                        ? '✅ Equipped to $slotName (Atk: ${stats['attackMin']}–${stats['attackMax']}, Def: ${stats['defense']})'
                                        : '✅ Equipped to $slotName',
                                  ),
                                ),
                              );
                            } catch (e) {
                              messenger.showSnackBar(
                                SnackBar(content: Text('⚠️ Failed to equip: $e')),
                              );
                            } finally {
                              if (mounted) {
                                setState(() {
                                  _isLoading = false;
                                  _activeDocId = null;
                                });
                              }
                            }
                          },
                        ),
                        const SizedBox(width: 8),

                        // Move to Backpack
                        TokenIconButton(
                          glass: glass,
                          text: text,
                          buttons: buttons,
                          variant: TokenButtonVariant.outline,
                          icon: isActive
                              ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : const Icon(Icons.backpack),
                          label: const Text("Backpack"),
                          onPressed: isActive
                              ? null
                              : () async {
                            // ✅ Capture messenger BEFORE any await
                            final messenger = ScaffoldMessenger.of(context);

                            setState(() {
                              _isLoading = true;
                              _activeDocId = doc.id;
                            });
                            try {
                              final callable = FirebaseFunctions.instance
                                  .httpsCallable('storeItemInBackpack');
                              await callable.call({
                                'heroId': widget.heroId,
                                'itemDocId': doc.id,
                                if (widget.insideVillage) 'villageId': widget.villageId,
                                if (!widget.insideVillage) 'tileKey': tileKey,
                              });

                              messenger.showSnackBar(
                                const SnackBar(content: Text("🎒 Moved to backpack")),
                              );
                            } catch (e) {
                              messenger.showSnackBar(
                                SnackBar(content: Text('❌ Failed to store: $e')),
                              );
                            } finally {
                              if (mounted) {
                                setState(() {
                                  _isLoading = false;
                                  _activeDocId = null;
                                });
                              }
                            }
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
      case 'one_hand':
      case 'two_hand': // ✅ Two-handed → mainHand
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
