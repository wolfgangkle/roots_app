// lib/screens/home/main_home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:roots_app/modules/chat/chat_overlay.dart';
import 'package:roots_app/modules/heroes/views/hero_panel.dart';
import 'package:roots_app/screens/home/panels/main_content_panel.dart';
import 'package:roots_app/screens/home/panels/navigation_drawer.dart';
import 'package:roots_app/screens/controllers/main_content_controller.dart';
import 'package:roots_app/modules/village/views/village_panel.dart';
import 'package:roots_app/screens/home/panels/navigation_sidebar_panel.dart';
import 'package:roots_app/screens/helpers/layout_helper.dart';
import 'package:roots_app/modules/settings/models/user_settings_model.dart';
import 'package:roots_app/screens/home/mobile_tab_scaffold.dart' show MobileTabScaffold;
import 'package:roots_app/theme/app_style_manager.dart'; // for StyleManager/currentStyle
import 'package:roots_app/theme/widgets/themed_floating_banner.dart'; // floating banner


class MainHomeScreen extends StatelessWidget {
  const MainHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final contentController =
    Provider.of<MainContentController>(context, listen: false);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenSize = LayoutHelper.getSizeCategory(screenWidth);

    final showChat = context.watch<UserSettingsModel>().showChatOverlay;
    final style = context.watch<StyleManager>().currentStyle; // 🎨 tokens

    switch (screenSize) {
      case ScreenSizeCategory.small:
      // 🟦 MOBILE - Swipeable + Tappable Tab Layout
        return const MobileTabScaffold();

      case ScreenSizeCategory.medium:
      // 🟩 MEDIUM - 3-column layout with drawer + floating banner
        return Scaffold(
          backgroundColor: Colors.transparent,
          drawer: const NavigationDrawerPanel(),
          body: Column(
            children: [
              // 🌫️ Floating panoramic banner card (with drawer button)
              ThemedFloatingBanner(
                title: const Text('ROOTS'),
                heightOverride: style.banner.height,
                leading: Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                ),
                onTap: () {
                contentController.showWelcomeScreen();
              },
              ),
              // Main 3-column content
              Expanded(
                child: Row(
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
              ),
            ],
          ),
          // Keep your chat overlay FAB behavior for medium
          floatingActionButton:
          showChat ? const ChatOverlay(usePositioned: false) : null,
        );

      case ScreenSizeCategory.large:
      // 🟥 LARGE - Full 4-column layout + floating banner
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              // Layout column with floating banner on top
              Column(
                children: [
                  ThemedFloatingBanner(
                    title: const Text('ROOTS'),
                    heightOverride: style.banner.height,
                    onTap: () {
                      contentController.showWelcomeScreen();
                    },
                  ),
                  Expanded(
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
                ],
              ),
              // Positioned chat overlay for large
              if (showChat) const ChatOverlay(usePositioned: true),
            ],
          ),
        );
    }
  }
}
