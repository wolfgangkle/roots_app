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
    // 🔁 tokens
    context.watch<StyleManager>();
    final glass = kStyle.glass;
    final text = kStyle.textOnGlass;
    final buttons = kStyle.buttons;
    final pad = kStyle.card.padding;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return Center(child: Text("⚠️ Not logged in.", style: TextStyle(color: text.secondary)));
    }

    final heroRef = FirebaseFirestore.instance.collection('heroes').doc(widget.heroId);

    return StreamBuilder<DocumentSnapshot>(
      stream: heroRef.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(child: Text("🚫 Hero not found.", style: TextStyle(color: text.secondary)));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final backpack = List<Map<String, dynamic>>.from(data['backpack'] ?? []);

        if (backpack.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text("🎒 Backpack is empty.", style: TextStyle(color: text.secondary)),
          );
        }

        // Use Column to avoid nested scrolling issues
        return Column(
          children: List.generate(backpack.length, (index) {
            final item = backpack[index];
            final itemId = item['itemId'];
            final quantity = (item['quantity'] ?? 1) as int;
            final meta = gameItems[itemId] ?? {};
            final stats = (item['craftedStats'] as Map<String, dynamic>?) ?? {};
            final itemName = (meta['name'] ?? itemId).toString();
            final slot = _determineEquipSlot(meta);
            final isThisActive = _activeIndex == index && _isLoading;

            // line of stats text
            final statsLine = stats.isNotEmpty
                ? stats.entries.map((e) => "${e.key}: ${e.value}").join(' • ')
                : null;

            final row = Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.backpack, size: 20),
                const SizedBox(width: 10),
                // Texts
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("$itemName ×$quantity",
                          style: TextStyle(
                            color: text.primary,
                            fontWeight: FontWeight.w600,
                          )),
                      if (statsLine != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          statsLine,
                          style: TextStyle(color: text.secondary, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Actions
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Equip
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
                          _activeIndex = index;
                        });
                        try {
                          final callable = FirebaseFunctions.instance
                              .httpsCallable('equipItemFromBackpack');
                          final result = await callable.call({
                            'heroId': widget.heroId,
                            'backpackIndex': index,
                            'slot': slot,
                          });

                          if (context.mounted) {
                            final s = result.data['updatedStats'];
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  s != null
                                      ? "🛡 Equipped to $slot\nAtk: ${s['attackMin']}-${s['attackMax']}, Def: ${s['defense']}"
                                      : "🛡 Equipped to $slot",
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
                                content:
                                Text("❌ Failed to equip: $e", style: TextStyle(color: text.primary)),
                                backgroundColor:
                                glass.baseColor.withValues(alpha: glass.opacity),
                              ),
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isThisActive)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            const Icon(Icons.check, size: 18),
                          const SizedBox(width: 6),
                          const Text('Equip'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Drop
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
                          _activeIndex = index;
                        });
                        try {
                          final callable =
                          FirebaseFunctions.instance.httpsCallable('dropHeroItem');
                          final result = await callable.call({
                            'heroId': widget.heroId,
                            'backpackIndex': index,
                            'quantity': 1,
                            if (widget.insideVillage) 'villageId': widget.villageId,
                            if (!widget.insideVillage)
                              'tileKey': '${widget.tileX}_${widget.tileY}',
                          });

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "📦 Dropped ${result.data['quantity']}x ${result.data['itemId']}",
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
                                content:
                                Text("❌ Failed to drop item: $e", style: TextStyle(color: text.primary)),
                                backgroundColor:
                                glass.baseColor.withValues(alpha: glass.opacity),
                              ),
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isThisActive)
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
              child: TokenPanel(
                glass: glass,
                text: text,
                padding: EdgeInsets.fromLTRB(pad.left, 10, pad.right, 10),
                child: row,
              ),
            );
          }),
        );
      },
    );
  }

  String _determineEquipSlot(Map<String, dynamic> meta) {
    final raw = meta['equipSlot']?.toString().toLowerCase() ?? 'main_hand';
    switch (raw) {
      case 'main_hand':
      case 'one_hand':
      case 'two_hand': // two-handed → mainHand
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
