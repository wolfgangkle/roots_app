import 'package:flutter/material.dart';
import 'package:roots_app/modules/village/widgets/crafting_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roots_app/modules/village/widgets/crafting_progress_indicator.dart';

class CraftingCard extends StatelessWidget {
  final String itemId;
  final Map<String, dynamic> itemData;
  final String villageId;
  final bool isDisabled;
  final Widget? craftingButtonWidget;
  final Map<String, dynamic>? currentCraftingJob; // ✅ NEW

  const CraftingCard({
    super.key,
    required this.itemId,
    required this.itemData,
    required this.villageId,
    this.isDisabled = false,
    this.craftingButtonWidget,
    this.currentCraftingJob,
  });

  @override
  Widget build(BuildContext context) {
    final name = itemData['name'] ?? 'Unnamed';
    final type = itemData['type'] ?? 'Unknown';
    final craftingCost = itemData['craftingCost'] as Map<String, dynamic>? ?? {};
    final baseStats = itemData['baseStats'] as Map<String, dynamic>? ?? {};

    final costString = craftingCost.entries
        .map((e) => '${e.value} ${_capitalize(e.key)}')
        .join(', ');

    final isCraftingThisItem = currentCraftingJob != null &&
        currentCraftingJob!['itemId'] == itemId;

    return Container(
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
            name,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text('🧪 Type: ${_capitalize(type)}'),
          const SizedBox(height: 4),
          Text('💸 Cost: $costString'),

          if (baseStats.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('📊 Stats:', style: TextStyle(color: Colors.grey.shade600)),
            ...baseStats.entries.map((e) => Text('• ${_capitalize(e.key)}: ${e.value}')),
          ],

          const SizedBox(height: 12),

          if (craftingButtonWidget != null)
            Align(
              alignment: Alignment.centerRight,
              child: craftingButtonWidget!,
            ),

          if (isCraftingThisItem) ...[
            const SizedBox(height: 12),
            CraftingProgressIndicator(
              startedAt: (currentCraftingJob!['startedAt'] as Timestamp).toDate(),
              endsAt: (currentCraftingJob!['startedAt'] as Timestamp)
                  .toDate()
                  .add(Duration(seconds: currentCraftingJob!['durationSeconds'] ?? 0)),
              villageId: villageId,
            ),
          ],
        ],
      ),
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
