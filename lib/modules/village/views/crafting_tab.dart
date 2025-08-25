import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:roots_app/modules/village/data/items.dart';
import 'package:roots_app/modules/village/widgets/crafting_button.dart';
import 'package:roots_app/modules/village/widgets/crafting_card.dart';

// 🔷 Tokens
import 'package:roots_app/theme/app_style_manager.dart';
import 'package:roots_app/theme/widgets/token_panels.dart';
import 'package:roots_app/theme/tokens.dart';

class CraftingTab extends StatefulWidget {
  final String villageId;
  final Map<String, dynamic>? currentCraftingJob;
  final String selectedFilter;

  const CraftingTab({
    super.key,
    required this.villageId,
    required this.currentCraftingJob,
    required this.selectedFilter,
  });

  @override
  State<CraftingTab> createState() => _CraftingTabState();
}

class _CraftingTabState extends State<CraftingTab> {
  bool isCraftingInProgress = false;

  void _onCraftStart() {
    setState(() => isCraftingInProgress = true);
  }

  @override
  void didUpdateWidget(covariant CraftingTab oldWidget) {
    super.didUpdateWidget(oldWidget);

    // ✅ Reset button lock if the crafting job was just cleared
    if (oldWidget.currentCraftingJob != null &&
        widget.currentCraftingJob == null &&
        isCraftingInProgress) {
      setState(() {
        isCraftingInProgress = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔄 Live-reactive tokens
    context.watch<StyleManager>();
    final GlassTokens glass = kStyle.glass;
    final TextOnGlassTokens text = kStyle.textOnGlass;
    final EdgeInsets cardPad = kStyle.card.padding;

    final entries = gameItems.entries.toList();

    final filtered = entries.where((entry) {
      if (widget.selectedFilter == 'All') return true;
      final normalized = _normalizedType(widget.selectedFilter);
      return normalized.isEmpty ||
          (entry.value['type'] as String?)?.toLowerCase() == normalized;
    }).toList();

    final allDisabled =
        isCraftingInProgress || widget.currentCraftingJob != null;

    if (filtered.isEmpty) {
      return Padding(
        padding: EdgeInsets.fromLTRB(cardPad.left, 12, cardPad.right, cardPad.bottom),
        child: TokenPanel(
          glass: glass,
          text: text,
          padding: EdgeInsets.fromLTRB(cardPad.left, 14, cardPad.right, 14),
          child: Text(
            "🚫 No matching items.",
            style: TextStyle(color: text.secondary),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(cardPad.left, 12, cardPad.right, cardPad.bottom),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final itemId = filtered[index].key;
        final item = filtered[index].value;

        return CraftingCard(
          itemId: itemId,
          itemData: item,
          villageId: widget.villageId,
          isDisabled: allDisabled,
          currentCraftingJob: widget.currentCraftingJob,
          craftingButtonWidget: CraftButton(
            itemId: itemId,
            villageId: widget.villageId,
            isDisabled: allDisabled,
            label: allDisabled ? 'Crafting...' : 'Craft',
            onCraftStart: _onCraftStart,
          ),
        );
      },
    );
  }

  String _normalizedType(String filter) {
    switch (filter.toLowerCase()) {
      case 'weapons':
        return 'weapon';
      case 'armor':
        return 'armor';
      case 'other':
        return 'other';
      default:
        return '';
    }
  }
}
