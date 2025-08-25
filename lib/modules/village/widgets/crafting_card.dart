import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import 'package:roots_app/modules/village/widgets/crafting_progress_indicator.dart';

// 🔷 Tokens
import 'package:roots_app/theme/app_style_manager.dart';
import 'package:roots_app/theme/widgets/token_panels.dart';
import 'package:roots_app/theme/tokens.dart';

class CraftingCard extends StatelessWidget {
  final String itemId;
  final Map<String, dynamic> itemData;
  final String villageId;
  final bool isDisabled;
  final Widget? craftingButtonWidget;
  final Map<String, dynamic>? currentCraftingJob;

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
    // 🔄 Live tokens
    context.watch<StyleManager>();
    final GlassTokens glass = kStyle.glass;
    final TextOnGlassTokens text = kStyle.textOnGlass;
    final EdgeInsets cardPad = kStyle.card.padding;

    final String name = (itemData['name'] ?? 'Unnamed').toString();
    final String type = (itemData['type'] ?? 'Unknown').toString();

    final Map<String, dynamic> craftingCost =
    Map<String, dynamic>.from(itemData['craftingCost'] ?? {});
    final Map<String, dynamic> baseStats =
    Map<String, dynamic>.from(itemData['baseStats'] ?? {});

    final String costString = craftingCost.entries
        .map((e) => '${e.value} ${_capitalize(e.key)}')
        .join(', ');

    final int buildTimeSeconds = itemData['buildTime'] is int
        ? itemData['buildTime'] as int
        : int.tryParse(itemData['buildTime'].toString()) ?? 0;

    final String buildTimeText = _formatDuration(Duration(seconds: buildTimeSeconds));

    final bool isCraftingThisItem =
        currentCraftingJob != null && currentCraftingJob!['itemId'] == itemId;

    return TokenPanel(
      glass: glass,
      text: text,
      padding: EdgeInsets.fromLTRB(cardPad.left, 12, cardPad.right, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🏷 Name
          Text(
            name,
            style: TextStyle(
              color: text.primary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),

          // 🧪 Type
          Text('🧪 Type: ${_capitalize(type)}', style: TextStyle(color: text.secondary)),

          // 💸 Cost + Duration
          const SizedBox(height: 4),
          Text('💸 Cost: $costString', style: TextStyle(color: text.secondary)),
          Text('⏳ Craft Time: $buildTimeText', style: TextStyle(color: text.secondary)),

          // 📊 Stats
          if (baseStats.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('📊 Stats:', style: TextStyle(color: text.subtle)),
            const SizedBox(height: 4),
            ...baseStats.entries.map(
                  (e) => Text(
                '• ${_capitalize(e.key)}: ${e.value}',
                style: TextStyle(color: text.secondary),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // 🔘 Button
          if (craftingButtonWidget != null)
            Align(alignment: Alignment.centerRight, child: craftingButtonWidget!),

          // ⏳ Progress
          if (isCraftingThisItem) ...[
            const SizedBox(height: 12),
            CraftingProgressIndicator(
              startedAt: (currentCraftingJob!['startedAt'] as Timestamp).toDate(),
              endsAt: (currentCraftingJob!['startedAt'] as Timestamp)
                  .toDate()
                  .add(Duration(seconds: currentCraftingJob!['durationSeconds'] as int? ?? 0)),
              villageId: villageId,
            ),
          ],
        ],
      ),
    );
  }

  String _capitalize(String text) =>
      text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (minutes == 0) return '$seconds s';
    return seconds == 0 ? '$minutes min' : '$minutes min $seconds s';
  }
}
