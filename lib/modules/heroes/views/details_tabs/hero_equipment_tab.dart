import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roots_app/modules/heroes/widgets/equipment_slots_view.dart';
import 'package:roots_app/modules/heroes/widgets/hero_backpack_list.dart';
import 'package:roots_app/modules/heroes/widgets/tile_or_village_item_list.dart';
import 'package:roots_app/modules/heroes/widgets/hero_weight_bar.dart'; // ✅ NEW

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

        if (insideVillage &&
            snapshot.hasData &&
            snapshot.data!.docs.isNotEmpty) {
          resolvedVillageId = snapshot.data!.docs.first.id;
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: heroRef.snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;
            final heroState = data['state'] ?? 'idle';
            final currentWeight = (data['currentWeight'] ?? 0).toDouble();
            final carryCapacity = (data['carryCapacity'] ?? 1).toDouble();

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🆙 Weight bar moved to the top
                  HeroWeightBar(
                    currentWeight: currentWeight,
                    carryCapacity: carryCapacity,
                  ),
                  const SizedBox(height: 16),

                  EquipmentSlotsView(
                    heroId: heroId,
                    tileX: tileX,
                    tileY: tileY,
                    villageId: resolvedVillageId,
                    insideVillage: insideVillage,
                  ),
                  const Divider(height: 24),
                  HeroBackpackList(
                    heroId: heroId,
                    tileX: tileX,
                    tileY: tileY,
                    villageId: resolvedVillageId,
                    insideVillage: insideVillage,
                  ),
                  const Divider(height: 24),
                  if (heroState == 'idle') ...[
                    TileOrVillageItemList(
                      heroId: heroId,
                      insideVillage: insideVillage,
                      tileX: tileX,
                      tileY: tileY,
                      villageId: resolvedVillageId,
                    ),
                  ] else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          "⚠️ You cannot access external storage while in state: $heroState.",
                          style: TextStyle(color: Colors.orange.shade800),
                        ),
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
