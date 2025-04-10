import 'package:flutter/material.dart'; // ✅ required for Text, Center, etc.
import 'package:provider/provider.dart';
import 'package:roots_app/screens/home/panels/chat_overlay.dart';
import 'package:roots_app/screens/home/panels/chat_panel.dart';
import 'package:roots_app/modules/heroes/views/hero_panel.dart';
import 'package:roots_app/screens/home/panels/main_content_panel.dart';
import 'package:roots_app/screens/home/panels/navigation_drawer.dart';
import 'package:roots_app/screens/controllers/main_content_controller.dart';
import 'package:roots_app/screens/home/mobile_tab_scaffold.dart';
import 'package:roots_app/modules/village/views/village_panel.dart';



class MainHomeScreen extends StatelessWidget {
  const MainHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final contentController = Provider.of<MainContentController>(context);

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 1024;
    final isMediumScreen = screenWidth >= 1024 && screenWidth < 1600;
    final isLargeScreen = screenWidth >= 1600;

    // 🟦 MOBILE - Swipeable + Tappable Tab Layout
    if (isSmallScreen) {
      return const MobileTabScaffold();
    }

    // 🟩 MEDIUM - 3-column layout with drawer
    if (isMediumScreen) {
      return Scaffold(
        appBar: AppBar(title: const Text('ROOTS')),
        drawer: NavigationDrawerPanel(), // (without const, since we'll pass state later)
        body: Row(
          children: [
            SizedBox(width: 400, child: HeroPanel(controller: contentController)),
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
              SizedBox(width: 400, child: HeroPanel(controller: contentController)),
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
