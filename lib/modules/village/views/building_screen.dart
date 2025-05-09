import 'package:flutter/material.dart';
import 'package:roots_app/modules/village/models/village_model.dart';
import 'package:roots_app/widgets/filter_bar.dart';
import 'package:roots_app/widgets/top_tab_selector.dart';
import 'package:roots_app/modules/village/views/building_tab.dart';
import 'package:roots_app/modules/village/views/crafting_tab.dart';

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

    return Column(
      children: [
        // 🔝 Top Tabs (Buildings / Crafting)
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

        // 🔍 Contextual Filters
        FilterBar(
          filters: currentTab == 'Buildings'
              ? ['All', 'Production', 'Storage']
              : ['All', 'Weapons', 'Armor', 'Other'],
          selected: currentFilter,
          onFilterSelected: (value) {
            setState(() => currentFilter = value);
          },
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
