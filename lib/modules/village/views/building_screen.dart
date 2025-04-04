import 'package:flutter/material.dart';
import 'package:roots_app/modules/village/models/village_model.dart';
import 'package:roots_app/widgets/filter_bar.dart';
import 'package:roots_app/widgets/top_tab_selector.dart';
import 'building_tab.dart';
import 'crafting_tab.dart';

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
    final simulated = widget.village.simulatedResources;

    return Column(
      children: [
        // 🔝 Top Tabs
        TopTabSelector(
          tabs: const ['Buildings', 'Crafting'],
          current: currentTab,
          onTabChanged: (value) {
            setState(() {
              currentTab = value;
              currentFilter = 'All'; // Reset filter on tab switch
            });
          },
        ),
        const SizedBox(height: 12),

        // 🔍 Filter buttons below tabs
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

        // 📋 Tab Content
        Expanded(
          child: currentTab == 'Buildings'
              ? BuildingTab(
            village: widget.village,
            selectedFilter: currentFilter,
          )
              : const CraftingTab(), // Just placeholder for now
        ),
      ],
    );
  }
}
