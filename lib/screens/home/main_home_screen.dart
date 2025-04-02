
import 'package:flutter/material.dart';
import 'mobile_tab_scaffold.dart';
import 'panels/hero_panel.dart';
import 'panels/main_content_panel.dart';
import 'package:roots_app/modules/village/views/village_panel.dart';
import 'panels/chat_overlay.dart';
import 'panels/chat_panel.dart';
import 'panels/navigation_drawer.dart';

class MainHomeScreen extends StatelessWidget {
  const MainHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
        drawer: const NavigationDrawerPanel(),
        body: Row(
          children: const [
            SizedBox(width: 250, child: HeroPanel()),
            VerticalDivider(width: 1),
            Expanded(flex: 2, child: MainContentPanel()),
            VerticalDivider(width: 1),
            SizedBox(width: 250, child: VillagePanel()),
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
            children: const [
              SizedBox(width: 200, child: NavigationDrawerPanel()),
              VerticalDivider(width: 1),
              SizedBox(width: 250, child: HeroPanel()),
              VerticalDivider(width: 1),
              Expanded(flex: 2, child: MainContentPanel()),
              VerticalDivider(width: 1),
              SizedBox(width: 250, child: VillagePanel()),
            ],
          ),
          const ChatOverlay(),
        ],
      ),
    );
  }
}
