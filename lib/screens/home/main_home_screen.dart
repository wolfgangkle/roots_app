import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:roots_app/modules/chat/chat_overlay.dart';
import 'package:roots_app/modules/heroes/views/hero_panel.dart';
import 'package:roots_app/screens/home/panels/main_content_panel.dart';
import 'package:roots_app/screens/home/panels/navigation_drawer.dart';
import 'package:roots_app/screens/controllers/main_content_controller.dart';
import 'package:roots_app/screens/home/mobile_tab_scaffold.dart';
import 'package:roots_app/modules/village/views/village_panel.dart';
import 'package:roots_app/screens/home/panels/navigation_sidebar_panel.dart';
import 'package:roots_app/screens/helpers/layout_helper.dart';

class MainHomeScreen extends StatelessWidget {
  const MainHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final contentController = Provider.of<MainContentController>(context, listen: false);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenSize = LayoutHelper.getSizeCategory(screenWidth);

    switch (screenSize) {
      case ScreenSizeCategory.small:
      // 🟦 MOBILE - Swipeable + Tappable Tab Layout
        return const MobileTabScaffold();

      case ScreenSizeCategory.medium:
      // 🟩 MEDIUM - 3-column layout with drawer
        return Scaffold(
          appBar: AppBar(title: const Text('ROOTS')),
          drawer: NavigationDrawerPanel(),
          body: Row(
            children: [
              SizedBox(width: 400, child: HeroPanel(controller: contentController)),
              const VerticalDivider(width: 1),
              Expanded(
                flex: 2,
                child: const MainContentPanel(),
              ),
              const VerticalDivider(width: 1),
              SizedBox(
                width: 400,
                child: VillagePanel(onVillageTap: contentController.showVillageCenter),
              ),
            ],
          ),
          floatingActionButton: const ChatOverlay(usePositioned: false), // 👈 FIXED
        );

      case ScreenSizeCategory.large:
      // 🟥 LARGE - Full 4-column layout
        return Scaffold(
          appBar: AppBar(title: const Text('ROOTS')),
          body: Stack(
            children: [
              Positioned.fill(
                child: Row(
                  children: [
                    const NavigationSidebarPanel(),
                    const VerticalDivider(width: 1),
                    SizedBox(width: 400, child: HeroPanel(controller: contentController)),
                    const VerticalDivider(width: 1),
                    Expanded(
                      flex: 2,
                      child: const MainContentPanel(),
                    ),
                    const VerticalDivider(width: 1),
                    SizedBox(
                      width: 400,
                      child: VillagePanel(onVillageTap: contentController.showVillageCenter),
                    ),
                  ],
                ),
              ),
              const ChatOverlay(usePositioned: true), // 👈 FIXED
            ],
          ),
        );
    }
  }
}
