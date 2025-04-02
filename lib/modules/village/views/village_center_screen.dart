import 'package:flutter/material.dart';
import '../models/village_model.dart';
import 'building_screen.dart';

enum VillageTab { buildings, equipment, storage }

class VillageCenterScreen extends StatefulWidget {
  final VillageModel village;

  const VillageCenterScreen({super.key, required this.village});

  @override
  State<VillageCenterScreen> createState() => _VillageCenterScreenState();
}

class _VillageCenterScreenState extends State<VillageCenterScreen> {
  VillageTab currentTab = VillageTab.buildings;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top tabs
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildTabButton(VillageTab.buildings, 'Buildings'),
            _buildTabButton(VillageTab.equipment, 'Equipment'),
            _buildTabButton(VillageTab.storage, 'Storage'),
          ],
        ),
        const Divider(),

        // Active tab content
        Expanded(
          child: _buildTabContent(),
        ),
      ],
    );
  }

  Widget _buildTabButton(VillageTab tab, String label) {
    final isSelected = currentTab == tab;
    return TextButton(
      onPressed: () {
        setState(() {
          currentTab = tab;
        });
      },
      child: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.blue : Colors.black,
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (currentTab) {
      case VillageTab.buildings:
        return BuildingScreen(village: widget.village);
      case VillageTab.equipment:
        return Center(child: Text('⚔️ Equipment view coming soon!'));
      case VillageTab.storage:
        return Center(child: Text('📦 Storage view coming soon!'));
      default:
        return const SizedBox.shrink();
    }
  }
}
