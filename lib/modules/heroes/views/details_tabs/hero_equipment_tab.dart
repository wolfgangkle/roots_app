import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:roots_app/modules/heroes/widgets/equipment_slots_view.dart';
import 'package:roots_app/modules/heroes/widgets/hero_backpack_list.dart';
import 'package:roots_app/modules/heroes/widgets/tile_or_village_item_list.dart';
import 'package:roots_app/modules/heroes/widgets/hero_weight_bar.dart';

// 🔷 Tokens
import 'package:provider/provider.dart';
import 'package:roots_app/theme/app_style_manager.dart';
import 'package:roots_app/theme/widgets/token_panels.dart';

class HeroEquipmentTab extends StatelessWidget {
  final String heroId;
  final bool insideVillage;
  final int tileX;
  final int tileY;

  const HeroEquipmentTab({
    super.key,
    required this.heroId,
    required this.insideVillage,
    required this.tileX,
    required this.tileY,
  });

  @override
  Widget build(BuildContext context) {
    // 🔁 Tokens (react to theme changes)
    context.watch<StyleManager>();
    final glass = kStyle.glass;
    final text = kStyle.textOnGlass;
    final cardPad = kStyle.card.padding;

    final heroRef = FirebaseFirestore.instance.collection('heroes').doc(heroId);

    final villageQuery = FirebaseFirestore.instance
        .collectionGroup('villages')
        .where('tileX', isEqualTo: tileX)
        .where('tileY', isEqualTo: tileY)
        .get();

    return FutureBuilder<QuerySnapshot>(
      future: villageQuery,
      builder: (context, snapshot) {
        String? resolvedVillageId;

        if (insideVillage && snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          resolvedVillageId = snapshot.data!.docs.first.id;
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: heroRef.snapshots(),
          builder: (context, snap) {
            if (!snap.hasData || !snap.data!.exists) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snap.data!.data() as Map<String, dynamic>;
            final heroState = data['state'] ?? 'idle';
            final currentWeight = (data['currentWeight'] ?? 0).toDouble();
            final carryCapacity = (data['carryCapacity'] ?? 1).toDouble();

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                cardPad.left,
                cardPad.top,
                cardPad.right,
                cardPad.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 🧺 Carry weight (boxed)
                  TokenPanel(
                    glass: glass,
                    text: text,
                    padding: EdgeInsets.fromLTRB(
                      cardPad.left,
                      14,
                      cardPad.right,
                      14,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Carry Weight',
                          style: TextStyle(
                            color: text.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        HeroWeightBar(
                          currentWeight: currentWeight,
                          carryCapacity: carryCapacity,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 🧩 Equipment (boxed)
                  TokenPanel(
                    glass: glass,
                    text: text,
                    padding: EdgeInsets.fromLTRB(
                      cardPad.left,
                      14,
                      cardPad.right,
                      14,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Equipment',
                          style: TextStyle(
                            color: text.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        EquipmentSlotsView(
                          heroId: heroId,
                          tileX: tileX,
                          tileY: tileY,
                          villageId: resolvedVillageId,
                          insideVillage: insideVillage,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 🎒 Backpack (boxed)
                  TokenPanel(
                    glass: glass,
                    text: text,
                    padding: EdgeInsets.fromLTRB(
                      cardPad.left,
                      14,
                      cardPad.right,
                      14,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Backpack',
                          style: TextStyle(
                            color: text.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        HeroBackpackList(
                          heroId: heroId,
                          tileX: tileX,
                          tileY: tileY,
                          villageId: resolvedVillageId,
                          insideVillage: insideVillage,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 🧱 Nearby storage / tile items (boxed)
                  if (heroState == 'idle')
                    TokenPanel(
                      glass: glass,
                      text: text,
                      padding: EdgeInsets.fromLTRB(
                        cardPad.left,
                        14,
                        cardPad.right,
                        14,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            insideVillage ? 'Village Storage' : 'Tile Items',
                            style: TextStyle(
                              color: text.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TileOrVillageItemList(
                            heroId: heroId,
                            insideVillage: insideVillage,
                            tileX: tileX,
                            tileY: tileY,
                            villageId: resolvedVillageId,
                          ),
                        ],
                      ),
                    )
                  else
                    TokenPanel(
                      glass: glass,
                      text: text,
                      padding: EdgeInsets.fromLTRB(
                        cardPad.left,
                        14,
                        cardPad.right,
                        14,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "You cannot access external storage while in state: $heroState.",
                              style: TextStyle(color: text.secondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
