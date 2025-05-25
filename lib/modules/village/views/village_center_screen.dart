import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:roots_app/modules/village/models/village_model.dart';
import 'package:roots_app/modules/village/services/village_service.dart';
import 'package:roots_app/modules/village/views/building_screen.dart';
import 'package:roots_app/modules/village/extensions/village_model_extension.dart';
import 'package:roots_app/modules/village/views/village_items_tab.dart';
import 'package:roots_app/modules/village/views/workers_tab.dart';
import 'package:roots_app/modules/village/views/trading_tab.dart';

enum VillageTab { buildings, items, storage, workers, trading }

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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTabButton(VillageTab.buildings, 'Buildings'),
                _buildTabButton(VillageTab.items, 'Items'),
                _buildTabButton(VillageTab.storage, 'Storage'),
                _buildTabButton(VillageTab.workers, 'Workers'),
                _buildTabButton(VillageTab.trading, 'Trading'),
              ],
            ),
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
            final _ = updatedVillage.simulatedResources;

            return Column(
              children: [
                if (updatedVillage.currentBuildJob != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.bolt),
                      label: const Text('🔥 Finish Building Now'),
                      onPressed: () async {
                        try {
                          await FirebaseFunctions.instance
                              .httpsCallable('devFinishNow')
                              .call({'villageId': updatedVillage.id});
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Upgrade finished!')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      },
                    ),
                  ),
                Expanded(
                  child: BuildingScreen(village: updatedVillage),
                ),
              ],
            );
          },
        );

      case VillageTab.items:
        return VillageItemsTab(villageId: widget.village.id);

      case VillageTab.storage:
        return const Center(child: Text('📦 Storage view coming soon!'));

      case VillageTab.workers:
        return WorkersTab(village: widget.village);

      case VillageTab.trading:
        return const TradingTab();
    }
  }
}
