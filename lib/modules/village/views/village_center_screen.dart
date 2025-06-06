import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:roots_app/modules/village/models/village_model.dart';
import 'package:roots_app/modules/village/services/village_service.dart';
import 'package:roots_app/modules/village/views/building_screen.dart';
import 'package:roots_app/modules/village/extensions/village_model_extension.dart';
import 'package:roots_app/modules/village/views/village_items_tab.dart';
import 'package:roots_app/modules/village/views/workers_tab.dart';
import 'package:roots_app/modules/village/views/trading_tab.dart';
import 'package:roots_app/modules/village/views/techtree_tab.dart';

// 🌿 Theme color
const Color kAccentGreenLight = Color(0xFF3B5743);

enum VillageTab { buildings, items, storage, workers, trading, techtree }

class VillageCenterScreen extends StatefulWidget {
  final String villageId;

  const VillageCenterScreen({super.key, required this.villageId});

  @override
  State<VillageCenterScreen> createState() => _VillageCenterScreenState();
}

class _VillageCenterScreenState extends State<VillageCenterScreen> {
  VillageTab currentTab = VillageTab.buildings;
  final VillageService villageService = VillageService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<VillageModel>(
      stream: villageService.watchVillage(widget.villageId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final village = snapshot.data!;
        final _ = village.simulatedResources;

        return Scaffold(
          appBar: AppBar(
            title: Text(village.name),
          ),
          body: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTabButton(VillageTab.buildings, 'Buildings'),
                    _buildTabButton(VillageTab.items, 'Items'),
                    _buildTabButton(VillageTab.storage, 'Storage'),
                    _buildTabButton(VillageTab.workers, 'Workers'),
                    _buildTabButton(VillageTab.trading, 'Trading'),
                    _buildTabButton(VillageTab.techtree, 'Techtree'),
                  ],
                ),
              ),
              const Divider(),
              Expanded(child: _buildTabContent(village)),
            ],
          ),
        );
      },
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
          color: isSelected ? kAccentGreenLight : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTabContent(VillageModel village) {
    switch (currentTab) {
      case VillageTab.buildings:
        return Column(
          children: [
            if (village.currentBuildJob != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.bolt),
                  label: const Text('🔥 Finish Building Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAccentGreenLight,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    try {
                      await FirebaseFunctions.instance
                          .httpsCallable('devFinishNow')
                          .call({'villageId': village.id});

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Upgrade finished!')),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  },
                ),
              ),
            Expanded(child: BuildingScreen(village: village)),
          ],
        );

      case VillageTab.items:
        return Column(
          children: [
            if (village.currentCraftingJob != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.bolt),
                  label: const Text('🔥 Finish Crafting Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF6B2C2C), // 🔥 crafting red
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    try {
                      await FirebaseFunctions.instance
                          .httpsCallable('devFinishCraftingNow')
                          .call({'villageId': village.id});

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Crafting job finished!')),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  },
                ),
              ),
            Expanded(child: VillageItemsTab(villageId: village.id)),
          ],
        );

      case VillageTab.storage:
        return const Center(child: Text('📦 Storage view coming soon!'));

      case VillageTab.workers:
        return WorkersTab(villageId: village.id);

      case VillageTab.trading:
        return TradingTab(
          villageId: village.id,
          maxResourceTrade: village.maxDailyResourceTradeAmount,
          maxGoldTrade: village.maxDailyGoldTradeAmount,
          tradedResourceToday: village.tradingToday['tradedResources'] ?? 0,
          tradedGoldToday: village.tradingToday['tradedGold'] ?? 0,
        );

      case VillageTab.techtree:
        return const TechtreeTab();
    }
  }
}
