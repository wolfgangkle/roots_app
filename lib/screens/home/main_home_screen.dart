import 'package:flutter/material.dart';
import 'mobile_tab_scaffold.dart';
import 'panels/hero_panel.dart';
import 'panels/main_content_panel.dart';
import 'package:roots_app/modules/village/views/village_panel.dart';
import 'panels/chat_overlay.dart';
import 'panels/navigation_drawer.dart';
import '../controllers/main_content_controller.dart'; // NEW!

class MainHomeScreen extends StatelessWidget {
  const MainHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final contentController = MainContentController();

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 1024;
    final isMediumScreen = screenWidth >= 1024 && screenWidth < 1600;
    final isLargeScreen = screenWidth >= 1600;

    // 🟦 MOBILE - Swipeable + Tappable Tab Layout
    if (isSmallScreen) {
      return MobileTabScaffold(contentController: contentController);
    }

    // 🟩 MEDIUM - 3-column layout with drawer
    if (isMediumScreen) {
      return Scaffold(
        appBar: AppBar(title: const Text('ROOTS')),
        drawer: const NavigationDrawerPanel(),
        body: Row(
          children: [
            const SizedBox(width: 400, child: HeroPanel()),
            const VerticalDivider(width: 1),
            Expanded(
              flex: 2,
              child: MainContentPanel(controller: contentController),
            ),
            const VerticalDivider(width: 1),
            SizedBox(
              width: 400,
              child: VillagePanel(onVillageTap: contentController.showVillageCenter),
            ),
          ],
        ),
        floatingActionButton: const ChatOverlay(),
      );
    }

    // 🟥 LARGE - Full 4-column layout
    return Scaffold(
      appBar: AppBar(title: const Text('ROOTS')),
      body: Stack(
        children: [
          Row(
            children: [
              const SizedBox(width: 200, child: NavigationDrawerPanel()),
              const VerticalDivider(width: 1),
              const SizedBox(width: 400, child: HeroPanel()),
              const VerticalDivider(width: 1),
              Expanded(
                flex: 2,
                child: MainContentPanel(controller: contentController),
              ),
              const VerticalDivider(width: 1),
              SizedBox(
                width: 400,
                child: VillagePanel(onVillageTap: contentController.showVillageCenter),
              ),
            ],
          ),
          const ChatOverlay(),
        ],
      ),
    );
  }
}
