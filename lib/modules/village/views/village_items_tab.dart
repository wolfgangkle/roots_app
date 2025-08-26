import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'package:roots_app/modules/village/data/items.dart';

// 🔷 Tokens
import 'package:roots_app/theme/app_style_manager.dart';
import 'package:roots_app/theme/widgets/token_panels.dart';
import 'package:roots_app/theme/widgets/token_buttons.dart';
import 'package:roots_app/theme/tokens.dart';

class VillageItemsTab extends StatefulWidget {
  final String villageId;

  const VillageItemsTab({super.key, required this.villageId});

  @override
  State<VillageItemsTab> createState() => _VillageItemsTabState();
}

class _VillageItemsTabState extends State<VillageItemsTab> {
  String selectedFilter = 'All';
  int? expandedIndex;

  @override
  Widget build(BuildContext context) {
    // 🔄 Live-reactive tokens
    context.watch<StyleManager>();
    final GlassTokens glass = kStyle.glass;
    final TextOnGlassTokens text = kStyle.textOnGlass;
    final ButtonTokens buttons = kStyle.buttons;
    final EdgeInsets cardPad = kStyle.card.padding;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return Padding(
        padding: EdgeInsets.fromLTRB(cardPad.left, 12, cardPad.right, cardPad.bottom),
        child: SizedBox(
          width: double.infinity, // <-- ensure full width
          child: TokenPanel(
            glass: glass,
            text: text,
            padding: EdgeInsets.fromLTRB(cardPad.left, 14, cardPad.right, 14),
            child: Text("⚠️ Not logged in.", style: TextStyle(color: text.secondary)),
          ),
        ),
      );
    }


    final itemsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('villages')
        .doc(widget.villageId)
        .collection('items');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 🔘 Filters
        Padding(
          padding: EdgeInsets.fromLTRB(cardPad.left, 12, cardPad.right, 0),
          child: TokenPanel(
            glass: glass,
            text: text,
            padding: EdgeInsets.fromLTRB(cardPad.left, 10, cardPad.right, 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterButton('All', glass, text, buttons),
                  const SizedBox(width: 6),
                  _filterButton('Weapons', glass, text, buttons),
                  const SizedBox(width: 6),
                  _filterButton('Armor', glass, text, buttons),
                  const SizedBox(width: 6),
                  _filterButton('Other', glass, text, buttons),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 📦 Items list
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: itemsRef.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Padding(
                  padding: EdgeInsets.fromLTRB(cardPad.left, 0, cardPad.right, cardPad.bottom),
                  child: TokenPanel(
                    glass: glass,
                    text: text,
                    padding: EdgeInsets.fromLTRB(cardPad.left, 14, cardPad.right, 14),
                    child: Text("🪶 No items stored in this village.", style: TextStyle(color: text.secondary)),
                  ),
                );
              }

              final itemDocs = snapshot.data!.docs;

              final filteredItems = itemDocs.where((doc) {
                final itemData = doc.data() as Map<String, dynamic>;
                final itemId = itemData['itemId'];
                final base = itemId != null ? gameItems[itemId] ?? {} : {};
                final type = (base['type'] ?? 'unknown').toString().toLowerCase();

                if (selectedFilter == 'All') return true;
                if (selectedFilter == 'Weapons') return type == 'weapon';
                if (selectedFilter == 'Armor') return type == 'armor';
                return type != 'weapon' && type != 'armor';
              }).toList();

              if (filteredItems.isEmpty) {
                return Padding(
                  padding: EdgeInsets.fromLTRB(cardPad.left, 0, cardPad.right, cardPad.bottom),
                  child: TokenPanel(
                    glass: glass,
                    text: text,
                    padding: EdgeInsets.fromLTRB(cardPad.left, 14, cardPad.right, 14),
                    child: Text("🔍 No items match this filter.", style: TextStyle(color: text.secondary)),
                  ),
                );
              }

              return ListView.separated(
                padding: EdgeInsets.fromLTRB(cardPad.left, 0, cardPad.right, cardPad.bottom),
                itemCount: filteredItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final itemData = filteredItems[index].data() as Map<String, dynamic>;
                  final quantity = itemData['quantity'] ?? 1;
                  final itemId = itemData['itemId'] as String?;
                  final base = itemId != null ? gameItems[itemId] ?? {} : {};
                  final name = (base['name'] ?? 'Unknown Item').toString();
                  final description = (base['description'] ?? '').toString();
                  final craftedStats = itemData['craftedStats'] as Map<String, dynamic>? ?? {};
                  final Map<String, dynamic> stats = {
                    ...?base['baseStats'] as Map<String, dynamic>?,
                    ...craftedStats,
                  };

                  final isExpanded = expandedIndex == index;

                  return GestureDetector(
                    onTap: () {
                      setState(() => expandedIndex = isExpanded ? null : index);
                    },
                    child: TokenPanel(
                      glass: glass,
                      text: text,
                      padding: EdgeInsets.fromLTRB(cardPad.left, 12, cardPad.right, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title row
                          Text(
                            '$name ×$quantity',
                            style: TextStyle(
                              color: text.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),

                          // Expanded details
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            child: isExpanded
                                ? Padding(
                              key: const ValueKey('expanded'),
                              padding: const EdgeInsets.only(top: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (description.isNotEmpty)
                                    Text(
                                      description,
                                      style: TextStyle(color: text.secondary),
                                    ),
                                  if (stats.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      '📊 Stats:',
                                      style: TextStyle(color: text.subtle),
                                    ),
                                    const SizedBox(height: 4),
                                    ...stats.entries.map(
                                          (e) => Text(
                                        '• ${_capitalize(e.key)}: ${e.value}',
                                        style: TextStyle(color: text.secondary),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            )
                                : const SizedBox.shrink(key: ValueKey('collapsed')),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _filterButton(String label, GlassTokens glass, TextOnGlassTokens text, ButtonTokens buttons) {
    final bool isSelected = selectedFilter == label;
    final variant = isSelected ? TokenButtonVariant.outline : TokenButtonVariant.ghost;

    return TokenButton(
      variant: variant,
      glass: glass,
      text: text,
      buttons: buttons,
      onPressed: () {
        setState(() {
          selectedFilter = label;
          expandedIndex = null;
        });
      },
      child: Text(
        label,
        style: TextStyle(
          color: text.primary,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }

  String _capitalize(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
}
