import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:roots_app/modules/village/data/items.dart';

// 🔷 Tokens
import 'package:roots_app/theme/app_style_manager.dart';
import 'package:roots_app/theme/widgets/token_panels.dart';
import 'package:roots_app/theme/widgets/token_buttons.dart';

class EquipmentSlotsView extends StatefulWidget {
  final String heroId;
  final int tileX;
  final int tileY;
  final String? villageId;
  final bool insideVillage;

  const EquipmentSlotsView({
    super.key,
    required this.heroId,
    required this.tileX,
    required this.tileY,
    required this.villageId,
    required this.insideVillage,
  });

  @override
  State<EquipmentSlotsView> createState() => _EquipmentSlotsViewState();
}

class _EquipmentSlotsViewState extends State<EquipmentSlotsView> {
  bool _isLoading = false;
  String? _activeSlot; // which slot is currently processing

  @override
  Widget build(BuildContext context) {
    // 🔁 Tokens
    context.watch<StyleManager>();
    final glass = kStyle.glass;
    final text = kStyle.textOnGlass;
    final buttons = kStyle.buttons;
    final pad = kStyle.card.padding;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return Center(
        child: Text("⚠️ Not logged in.", style: TextStyle(color: text.secondary)),
      );
    }

    final heroRef = FirebaseFirestore.instance.collection('heroes').doc(widget.heroId);

    return StreamBuilder<DocumentSnapshot>(
      stream: heroRef.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(
            child: Text("🚫 Hero not found.", style: TextStyle(color: text.secondary)),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final equipped = (data['equipped'] as Map<String, dynamic>?) ?? {};

        final slots = const [
          'helmet',
          'chest',
          'arms',
          'belt',
          'legs',
          'feet',
          'mainHand',
          'offHand',
        ];

        final mainHandItem = equipped['mainHand'];
        final isMainHandTwoHanded =
            (mainHandItem?['equipSlot'] ?? '').toString().toLowerCase() == 'two_hand';

        return Column(
          children: [
            ...slots.map((slot) {
              final item = equipped[slot];
              final itemId = item?['itemId'];
              final meta = itemId != null ? (gameItems[itemId] ?? {}) : null;

              final isBlocked = slot == 'offHand' && isMainHandTwoHanded;
              final hasItem = itemId != null;

              final titleText = slot[0].toUpperCase() + slot.substring(1);
              final subtitleText = isBlocked
                  ? 'Blocked by two-handed weapon'
                  : hasItem
                  ? (meta?['name'] ?? itemId)
                  : 'Empty';

              // Row content
              final row = Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    isBlocked
                        ? Icons.block
                        : (hasItem ? Icons.check_circle_outline : Icons.radio_button_unchecked),
                    size: 20,
                    color: isBlocked
                        ? text.subtle
                        : hasItem
                        ? text.primary
                        : text.secondary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(titleText,
                            style: TextStyle(
                              color: text.primary,
                              fontWeight: FontWeight.w600,
                            )),
                        const SizedBox(height: 2),
                        Text(
                          subtitleText,
                          style: TextStyle(
                            color: isBlocked ? text.subtle : text.secondary,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Actions (hidden if blocked or empty)
                  if (hasItem && !isBlocked)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Unequip → Backpack
                        TokenTextButton(
                          glass: glass,
                          text: text,
                          buttons: buttons,
                          variant: TokenButtonVariant.ghost,
                          onPressed: _isLoading
                              ? null
                              : () async {
                            setState(() {
                              _isLoading = true;
                              _activeSlot = slot;
                            });
                            try {
                              final callable = FirebaseFunctions.instance
                                  .httpsCallable('unequipItemToBackpack');
                              final result = await callable.call({
                                'heroId': widget.heroId,
                                'slot': slot,
                              });

                              final stats = result.data['updatedStats'];
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      stats != null
                                          ? '🎒 Unequipped $slot (Atk: ${stats['attackMin']}–${stats['attackMax']}, Def: ${stats['defense']})'
                                          : '🎒 Unequipped $slot',
                                      style: TextStyle(color: text.primary),
                                    ),
                                    backgroundColor:
                                    glass.baseColor.withValues(alpha: glass.opacity),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('❌ Failed to unequip: $e',
                                        style: TextStyle(color: text.primary)),
                                    backgroundColor:
                                    glass.baseColor.withValues(alpha: glass.opacity),
                                  ),
                                );
                              }
                            } finally {
                              if (mounted) {
                                setState(() {
                                  _isLoading = false;
                                  _activeSlot = null;
                                });
                              }
                            }
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_isLoading && _activeSlot == slot)
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              else
                                const Icon(Icons.backpack, size: 18),
                              const SizedBox(width: 6),
                              const Text('Unequip'),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Drop Item
                        TokenTextButton(
                          glass: glass,
                          text: text,
                          buttons: buttons,
                          variant: TokenButtonVariant.ghost,
                          onPressed: _isLoading
                              ? null
                              : () async {
                            setState(() {
                              _isLoading = true;
                              _activeSlot = slot;
                            });
                            final tileKey = "${widget.tileX}_${widget.tileY}";
                            try {
                              final callable = FirebaseFunctions.instance
                                  .httpsCallable('dropItemFromSlot');
                              await callable.call({
                                'heroId': widget.heroId,
                                'slot': slot,
                                if (widget.insideVillage) 'villageId': widget.villageId,
                                if (!widget.insideVillage) 'tileKey': tileKey,
                              });

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('📦 Dropped item from slot',
                                        style: TextStyle(color: text.primary)),
                                    backgroundColor:
                                    glass.baseColor.withValues(alpha: glass.opacity),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('❌ Failed to drop item: $e',
                                        style: TextStyle(color: text.primary)),
                                    backgroundColor:
                                    glass.baseColor.withValues(alpha: glass.opacity),
                                  ),
                                );
                              }
                            } finally {
                              if (mounted) {
                                setState(() {
                                  _isLoading = false;
                                  _activeSlot = null;
                                });
                              }
                            }
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_isLoading && _activeSlot == slot)
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              else
                                const Icon(Icons.backspace, size: 18),
                              const SizedBox(width: 6),
                              const Text('Drop'),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              );

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Opacity(
                  opacity: isBlocked ? 0.6 : 1.0,
                  child: TokenPanel(
                    glass: glass,
                    text: text,
                    padding: EdgeInsets.fromLTRB(pad.left, 10, pad.right, 10),
                    child: row,
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
