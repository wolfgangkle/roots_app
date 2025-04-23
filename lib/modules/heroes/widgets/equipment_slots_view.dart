import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:roots_app/modules/village/data/items.dart';

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
  String? _activeSlot; // optional: tracks which slot is spinning

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
        final equipped = data['equipped'] as Map<String, dynamic>? ?? {};

        final slots = [
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text('🎽 Equipped Items', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ...slots.map((slot) {
              final item = equipped[slot];
              final itemId = item?['itemId'];
              final meta = itemId != null ? gameItems[itemId] ?? {} : null;

              final isBlocked = slot == 'offHand' && isMainHandTwoHanded;

              return ListTile(
                leading: Icon(isBlocked ? Icons.lock : Icons.check_circle_outline),
                title: Text(
                  slot[0].toUpperCase() + slot.substring(1),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: isBlocked
                    ? const Text('Blocked by two-handed weapon')
                    : itemId != null
                    ? Text(meta?['name'] ?? itemId)
                    : const Text('Empty'),
                tileColor: isBlocked ? Colors.grey.shade100 : null,
                trailing: (itemId != null && !isBlocked)
                    ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: (_isLoading && _activeSlot == slot)
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Icon(Icons.backpack),
                      tooltip: 'Unequip to Backpack',
                      onPressed: _isLoading
                          ? null
                          : () async {
                        setState(() {
                          _isLoading = true;
                          _activeSlot = slot;
                        });
                        try {
                          final callable = FirebaseFunctions.instance.httpsCallable('unequipItemToBackpack');
                          final result = await callable.call({
                            'heroId': widget.heroId,
                            'slot': slot,
                          });

                          final stats = result.data['updatedStats'];
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('🎒 Unequipped $slot (Atk: ${stats['attackMin']}–${stats['attackMax']}, Def: ${stats['defense']})')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("❌ Failed to unequip: $e")),
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
                    ),
                    IconButton(
                      icon: (_isLoading && _activeSlot == slot)
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Icon(Icons.backspace),
                      tooltip: 'Drop Item',
                      onPressed: _isLoading
                          ? null
                          : () async {
                        setState(() {
                          _isLoading = true;
                          _activeSlot = slot;
                        });
                        final tileKey = "${widget.tileX}_${widget.tileY}";
                        try {
                          final callable = FirebaseFunctions.instance.httpsCallable('dropItemFromSlot');
                          await callable.call({
                            'heroId': widget.heroId,
                            'slot': slot,
                            if (widget.insideVillage) 'villageId': widget.villageId,
                            if (!widget.insideVillage) 'tileKey': tileKey,
                          });

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("📦 Dropped item from slot")),
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
                              _activeSlot = null;
                            });
                          }
                        }
                      },
                    ),
                  ],
                )
                    : null,
              );
            }),
          ],
        );
      },
    );
  }
}
