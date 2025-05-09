import 'package:flutter/material.dart';
import 'package:roots_app/modules/village/models/village_model.dart';
import 'package:roots_app/modules/village/services/village_service.dart';
import 'package:roots_app/modules/village/views/building_screen.dart';
import 'package:roots_app/modules/village/extensions/village_model_extension.dart';
import 'package:roots_app/modules/village/views/village_items_tab.dart';

enum VillageTab { buildings, items, storage }

class VillageCenterScreen extends StatefulWidget {
  final VillageModel village;

  const VillageCenterScreen({super.key, required this.village});

  @override
  State<VillageCenterScreen> createState() => _VillageCenterScreenState();
}

class _VillageCenterScreenState extends State<VillageCenterScreen> {
  VillageTab currentTab = VillageTab.buildings;
  final VillageService villageService = VillageService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.village.name),
      ),
      body: Column(
        children: [
          // Top tabs
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTabButton(VillageTab.buildings, 'Buildings'),
              _buildTabButton(VillageTab.items, 'Items'),
              _buildTabButton(VillageTab.storage, 'Storage'),
            ],
          ),
          const Divider(),
          // Active tab content
          Expanded(
            child: _buildTabContent(),
          ),
        ],
      ),
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
        return StreamBuilder<VillageModel>(
          stream: villageService.getVillageStream(widget.village.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData) {
              return const Center(child: Text('Village not found'));
            }

            final updatedVillage = snapshot.data!;
            final _ = updatedVillage.simulatedResources; // ✅ Trigger simulation

            return BuildingScreen(village: updatedVillage);
          },
        );
      case VillageTab.items:
        return VillageItemsTab(villageId: widget.village.id);
      case VillageTab.storage:
        return const Center(child: Text('📦 Storage view coming soon!'));
    }
  }
}
