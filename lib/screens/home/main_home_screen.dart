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
import 'package:roots_app/modules/settings/models/user_settings_model.dart';

class MainHomeScreen extends StatelessWidget {
  const MainHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final contentController =
    Provider.of<MainContentController>(context, listen: false);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenSize = LayoutHelper.getSizeCategory(screenWidth);

    final showChat =
        context.watch<UserSettingsModel>().showChatOverlay;

    switch (screenSize) {
      case ScreenSizeCategory.small:
      // 🟦 MOBILE - Swipeable + Tappable Tab Layout
        return const MobileTabScaffold();

      case ScreenSizeCategory.medium:
      // 🟩 MEDIUM - 3-column layout with drawer
        return Scaffold(
          backgroundColor: Colors
              .transparent, // 👈 allow our global background to shine
          appBar: AppBar(
            title: const Text('ROOTS'),
            backgroundColor: Colors
                .transparent, // 👈 make the AppBar glassy later
            elevation: 0,
          ),
          drawer: NavigationDrawerPanel(),
          body: Row(
            children: [
              SizedBox(
                width: 400,
                child: HeroPanel(controller: contentController),
              ),
              const VerticalDivider(width: 1),
              const Expanded(
                flex: 2,
                child: MainContentPanel(),
              ),
              const VerticalDivider(width: 1),
              SizedBox(
                width: 400,
                child: VillagePanel(
                  onVillageTap: contentController.showVillageCenter,
                ),
              ),
            ],
          ),
          floatingActionButton: showChat
              ? const ChatOverlay(usePositioned: false)
              : null,
        );

      case ScreenSizeCategory.large:
      // 🟥 LARGE - Full 4-column layout
        return Scaffold(
          backgroundColor: Colors
              .transparent, // 👈 important for large screen too
          appBar: AppBar(
            title: const Text('ROOTS'),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: Stack(
            children: [
              Positioned.fill(
                child: Row(
                  children: [
                    const NavigationSidebarPanel(),
                    const VerticalDivider(width: 1),
                    SizedBox(
                      width: 400,
                      child: HeroPanel(controller: contentController),
                    ),
                    const VerticalDivider(width: 1),
                    const Expanded(
                      flex: 2,
                      child: MainContentPanel(),
                    ),
                    const VerticalDivider(width: 1),
                    SizedBox(
                      width: 400,
                      child: VillagePanel(
                        onVillageTap: contentController.showVillageCenter,
                      ),
                    ),
                  ],
                ),
              ),
              if (showChat)
                const ChatOverlay(usePositioned: true),
            ],
          ),
        );
    }
  }
}
