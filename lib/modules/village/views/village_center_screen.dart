import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:provider/provider.dart';

import 'package:roots_app/modules/village/models/village_model.dart';
import 'package:roots_app/modules/village/services/village_service.dart';
import 'package:roots_app/modules/village/views/building_screen.dart';
import 'package:roots_app/modules/village/extensions/village_model_extension.dart';
import 'package:roots_app/modules/village/views/village_items_tab.dart';
import 'package:roots_app/modules/village/views/workers_tab.dart';
import 'package:roots_app/modules/village/views/trading_tab.dart';
import 'package:roots_app/modules/village/views/techtree_tab.dart';

// 🔷 Tokens
import 'package:roots_app/theme/app_style_manager.dart';
import 'package:roots_app/theme/widgets/token_panels.dart';
import 'package:roots_app/theme/widgets/token_buttons.dart';
import 'package:roots_app/theme/tokens.dart';

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
    // 🔄 Live tokens
    context.watch<StyleManager>();
    final glass = kStyle.glass;
    final text = kStyle.textOnGlass;
    final buttons = kStyle.buttons;
    final cardPad = kStyle.card.padding;

    return StreamBuilder<VillageModel>(
      stream: villageService.watchVillage(widget.villageId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final village = snapshot.data!;
        final _ = village.simulatedResources; // keep local sim up-to-date

        return Column(
          children: [
            // 🔝 Header: name + tabs
            TokenPanel(
              glass: glass,
              text: text,
              padding: EdgeInsets.fromLTRB(cardPad.left, 14, cardPad.right, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    village.name,
                    style: TextStyle(
                      color: text.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _tabButton(VillageTab.buildings, 'Buildings', glass, text, buttons),
                        const SizedBox(width: 6),
                        _tabButton(VillageTab.items, 'Items', glass, text, buttons),
                        const SizedBox(width: 6),
                        _tabButton(VillageTab.storage, 'Storage', glass, text, buttons),
                        const SizedBox(width: 6),
                        _tabButton(VillageTab.workers, 'Workers', glass, text, buttons),
                        const SizedBox(width: 6),
                        _tabButton(VillageTab.trading, 'Trading', glass, text, buttons),
                        const SizedBox(width: 6),
                        _tabButton(VillageTab.techtree, 'Techtree', glass, text, buttons),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 📦 Content
            Expanded(child: _buildTabContent(context, village, glass, text, buttons, cardPad)),
          ],
        );
      },
    );
  }

  Widget _tabButton(
      VillageTab tab,
      String label,
      GlassTokens glass,
      TextOnGlassTokens text,
      ButtonTokens buttons,
      ) {
    final bool isSelected = currentTab == tab;

    // Selected → outline; Unselected → ghost
    final variant = isSelected ? TokenButtonVariant.outline : TokenButtonVariant.ghost;

    return TokenButton(
      variant: variant,
      glass: glass,
      text: text,
      buttons: buttons,
      onPressed: () => setState(() => currentTab = tab),
      child: Text(
        label,
        style: TextStyle(
          color: text.primary,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTabContent(
      BuildContext context,
      VillageModel village,
      GlassTokens glass,
      TextOnGlassTokens text,
      ButtonTokens buttons,
      EdgeInsets cardPad,
      ) {
    switch (currentTab) {
      case VillageTab.buildings:
        return Column(
          children: [
            if (village.currentBuildJob != null)
              Padding(
                padding: EdgeInsets.fromLTRB(cardPad.left, 0, cardPad.right, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TokenIconButton(
                    glass: glass,
                    text: text,
                    buttons: buttons,
                    variant: TokenButtonVariant.primary,
                    icon: const Icon(Icons.bolt),
                    label: const Text('🔥 Finish Building Now'),
                    onPressed: () async {
                      // ✅ capture messenger BEFORE await to avoid using context across async gaps
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await FirebaseFunctions.instance
                            .httpsCallable('devFinishNow')
                            .call({'villageId': village.id});

                        if (!mounted) return;
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Upgrade finished!')),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    },
                  ),
                ),
              ),
            Expanded(child: BuildingScreen(village: village)),
          ],
        );

      case VillageTab.items:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (village.currentCraftingJob != null)
              Padding(
                padding: EdgeInsets.fromLTRB(cardPad.left, 0, cardPad.right, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TokenIconButton(
                    glass: glass,
                    text: text,
                    buttons: buttons,
                    variant: TokenButtonVariant.danger, // crafting "finish now" as danger
                    icon: const Icon(Icons.bolt),
                    label: const Text('🔥 Finish Crafting Now'),
                    onPressed: () async {
                      // ✅ capture messenger BEFORE await to avoid using context across async gaps
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await FirebaseFunctions.instance
                            .httpsCallable('devFinishCraftingNow')
                            .call({'villageId': village.id});

                        if (!mounted) return;
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Crafting job finished!')),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    },
                  ),
                ),
              ),
            Expanded(child: VillageItemsTab(villageId: village.id)),
          ],
        );

      case VillageTab.storage:
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: cardPad.horizontal / 2),
          child: SizedBox( // ← forces full width
            width: double.infinity,
            child: TokenPanel(
              glass: glass,
              text: text,
              padding: EdgeInsets.fromLTRB(cardPad.left, 14, cardPad.right, 14),
              child: Text('📦 Storage view coming soon!', style: TextStyle(color: text.secondary)),
            ),
          ),
        );


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
