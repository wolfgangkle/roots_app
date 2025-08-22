// lib/screens/home/mobile_tab_scaffold.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:roots_app/modules/chat/chat_panel.dart';
import 'package:roots_app/modules/heroes/views/hero_panel.dart';
import 'package:roots_app/screens/home/panels/navigation_drawer.dart';
import 'package:roots_app/modules/village/views/village_panel.dart';
import 'package:roots_app/modules/village/views/village_center_screen.dart';
import 'package:roots_app/screens/controllers/main_content_controller.dart';
import 'package:roots_app/modules/profile/models/user_profile_model.dart';
import 'package:roots_app/screens/home/welcome_screen.dart';

import 'package:roots_app/theme/widgets/themed_floating_banner.dart';
import 'package:roots_app/theme/app_style_manager.dart';

class MobileTabScaffold extends StatefulWidget {
  const MobileTabScaffold({super.key});

  @override
  State<MobileTabScaffold> createState() => _MobileTabScaffoldState();
}

class _MobileTabScaffoldState extends State<MobileTabScaffold>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late PageController _pageController;

  Widget? _dynamicTabContent;
  String? _dynamicTabTitle;

  int get _tabCount => _dynamicTabContent != null ? 4 : 3;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabCount, vsync: this, initialIndex: 0);
    _pageController = PageController(initialPage: 0);
  }

  void _recreateControllers({int initialIndex = 0}) {
    _tabController.dispose();
    _tabController = TabController(length: _tabCount, vsync: this, initialIndex: initialIndex);
    _pageController.jumpToPage(initialIndex);
    setState(() {}); // ensure TabBar/PageView rebuild with new controller
  }

  void setDynamicTab({required String title, required Widget content}) {
    setState(() {
      _dynamicTabTitle = title;
      _dynamicTabContent = content;
      // put user on the dynamic tab (leftmost) immediately
      _recreateControllers(initialIndex: 0);
    });
  }

  void clearDynamicTab() {
    setState(() {
      _dynamicTabTitle = null;
      _dynamicTabContent = null;
      // go back to first regular tab (Heroes)
      _recreateControllers(initialIndex: 0);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contentController = Provider.of<MainContentController>(context); // used by HeroPanel
    final style = context.watch<StyleManager>().currentStyle;

    // Build TabBar — dynamic tab FIRST (leftmost), then the 3 regular tabs
    final tabBar = TabBar(
      controller: _tabController,
      onTap: (index) {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      tabs: [
        if (_dynamicTabContent != null) Tab(text: _dynamicTabTitle), // 👈 leftmost
        const Tab(text: '🧙 Heroes'),
        const Tab(text: '🏰 Villages'),
        const Tab(text: '💬 Chat'),
      ],
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      drawer: Consumer<UserProfileModel>(
        builder: (context, profile, _) {
          return NavigationDrawerPanel(onSelectDynamicTab: setDynamicTab);
        },
      ),
      body: Column(
        children: [
          // Floating panoramic banner (with burger)
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
              // Replace/activate dynamic tab with Welcome and switch to it (index 0)
              setDynamicTab(title: 'Welcome', content: const WelcomeScreen());
            },
          ),

          // Tab bar under the floating banner
          Theme(
            data: Theme.of(context).copyWith(
              tabBarTheme: TabBarTheme(
                labelColor: style.textOnGlass.primary,
                unselectedLabelColor: style.textOnGlass.subtle,
                indicatorColor: style.textOnGlass.primary,
              ),
            ),
            child: tabBar,
          ),

          // Pages — order MUST match TabBar (dynamic first if present)
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) => _tabController.animateTo(index),
              children: [
                if (_dynamicTabContent != null) _dynamicTabContent!, // 👈 index 0
                HeroPanel(controller: contentController),
                VillagePanel(
                  onVillageTap: (village) {
                    // On mobile: push full-screen detail (keeps mobile UX snappy)
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => VillageCenterScreen(villageId: village.id),
                      ),
                    );
                  },
                ),
                Consumer<UserProfileModel>(
                  builder: (context, user, _) =>
                      ChatPanel(currentUserName: user.heroName),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
