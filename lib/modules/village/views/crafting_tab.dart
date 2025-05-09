import 'package:flutter/material.dart';
import 'package:roots_app/modules/village/data/items.dart';
import 'package:roots_app/modules/village/widgets/crafting_button.dart';
import 'package:roots_app/modules/village/widgets/crafting_card.dart';

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
    final entries = gameItems.entries.toList();

    final filtered = entries.where((entry) {
      if (widget.selectedFilter == 'All') return true;
      final normalized = _normalizedType(widget.selectedFilter);
      return normalized.isEmpty ||
          (entry.value['type'] as String?)?.toLowerCase() == normalized;
    }).toList();

    final allDisabled =
        isCraftingInProgress || widget.currentCraftingJob != null;

    return filtered.isEmpty
        ? const Center(child: Text("🚫 No matching items."))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
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
