import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:roots_app/modules/village/data/items.dart';

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
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return const Center(child: Text("⚠️ Not logged in."));
    }

    final itemsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('villages')
        .doc(widget.villageId)
        .collection('items');

    return Column(
      children: [
        const SizedBox(height: 8),
        ToggleButtons(
          isSelected: ['All', 'Weapons', 'Armor', 'Other']
              .map((f) => f == selectedFilter)
              .toList(),
          onPressed: (index) {
            setState(() {
              selectedFilter = ['All', 'Weapons', 'Armor', 'Other'][index];
              expandedIndex = null;
            });
          },
          borderRadius: BorderRadius.circular(6),
          selectedColor: Colors.white,
          fillColor: Colors.blue,
          color: Colors.black,
          children: const [
            Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('All')),
            Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Weapons')),
            Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Armor')),
            Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Other')),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: itemsRef.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("🪶 No items stored in this village."));
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

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: filteredItems.length,
                itemBuilder: (context, index) {
                  final itemData = filteredItems[index].data() as Map<String, dynamic>;
                  final quantity = itemData['quantity'] ?? 1;
                  final itemId = itemData['itemId'] as String?;
                  final base = itemId != null ? gameItems[itemId] ?? {} : {};
                  final name = base['name'] ?? 'Unknown Item';
                  final description = base['description'] ?? '';
                  final craftedStats = itemData['craftedStats'] as Map<String, dynamic>? ?? {};
                  final stats = {
                    ...?base['baseStats'] as Map<String, dynamic>?,
                    ...craftedStats,
                  };

                  final isExpanded = expandedIndex == index;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        expandedIndex = isExpanded ? null : index;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade200,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$name ×$quantity',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isExpanded) ...[
                            const SizedBox(height: 6),
                            if (description.isNotEmpty)
                              Text(
                                description,
                                style: const TextStyle(color: Colors.grey),
                              ),
                            const SizedBox(height: 8),
                            if (stats.isNotEmpty) ...[
                              Text('📊 Stats:',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: Colors.grey.shade600)),
                              ...stats.entries.map(
                                    (e) => Text('• ${_capitalize(e.key)}: ${e.value}'),
                              ),
                            ],
                          ],
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

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
