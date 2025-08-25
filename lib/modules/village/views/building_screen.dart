import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:roots_app/modules/village/models/village_model.dart';
import 'package:roots_app/widgets/filter_bar.dart';
import 'package:roots_app/widgets/top_tab_selector.dart';
import 'package:roots_app/modules/village/views/building_tab.dart';
import 'package:roots_app/modules/village/views/crafting_tab.dart';

// 🔷 Tokens
import 'package:roots_app/theme/app_style_manager.dart';
import 'package:roots_app/theme/widgets/token_panels.dart';
import 'package:roots_app/theme/tokens.dart';

class BuildingScreen extends StatefulWidget {
  final VillageModel village;

  const BuildingScreen({super.key, required this.village});

  @override
  State<BuildingScreen> createState() => _BuildingScreenState();
}

class _BuildingScreenState extends State<BuildingScreen> {
  String currentTab = 'Buildings';
  String currentFilter = 'All';

  @override
  Widget build(BuildContext context) {
    // 🔄 Live-reactive tokens
    context.watch<StyleManager>();
    final GlassTokens glass = kStyle.glass;
    final TextOnGlassTokens text = kStyle.textOnGlass;
    final EdgeInsets cardPad = kStyle.card.padding;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 🔝 Tokenized header panel: tabs + contextual filters
        TokenPanel(
          glass: glass,
          text: text,
          padding: EdgeInsets.fromLTRB(
            cardPad.left,
            12,
            cardPad.right,
            12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TopTabSelector(
                tabs: const ['Buildings', 'Crafting'],
                current: currentTab,
                onTabChanged: (value) {
                  setState(() {
                    currentTab = value;
                    currentFilter = 'All'; // 🔄 Reset filter when switching tabs
                  });
                },
              ),
              const SizedBox(height: 12),
              FilterBar(
                filters: currentTab == 'Buildings'
                    ? const ['All', 'Production', 'Storage']
                    : const ['All', 'Weapons', 'Armor', 'Other'],
                selected: currentFilter,
                onFilterSelected: (value) {
                  setState(() => currentFilter = value);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 📋 Dynamic Tab Content
        Expanded(
          child: currentTab == 'Buildings'
              ? BuildingTab(
            village: widget.village,
            selectedFilter: currentFilter,
          )
              : CraftingTab(
            villageId: widget.village.id,
            currentCraftingJob: widget.village.currentCraftingJob,
            selectedFilter: currentFilter,
          ),
        ),
      ],
    );
  }
}
