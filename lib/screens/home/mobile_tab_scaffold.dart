import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:roots_app/modules/chat/chat_panel.dart';
import 'package:roots_app/modules/heroes/views/hero_panel.dart';
import 'package:roots_app/screens/home/panels/navigation_drawer.dart';
import 'package:roots_app/modules/village/views/village_panel.dart';
import 'package:roots_app/modules/village/views/village_center_screen.dart';
import 'package:roots_app/screens/controllers/main_content_controller.dart';
import 'package:roots_app/profile/models/user_profile_model.dart';

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
  }

  void setDynamicTab({required String title, required Widget content}) {
    setState(() {
      _dynamicTabTitle = title;
      _dynamicTabContent = content;
      _recreateControllers(initialIndex: 0);
    });
  }

  void clearDynamicTab() {
    setState(() {
      _dynamicTabTitle = null;
      _dynamicTabContent = null;
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
    final contentController = Provider.of<MainContentController>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ROOTS'),
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          tabs: [
            if (_dynamicTabContent != null) Tab(text: _dynamicTabTitle),
            const Tab(text: '🧙 Heroes'),
            const Tab(text: '🏰 Villages'),
            const Tab(text: '💬 Chat'),
          ],
        ),
      ),
      drawer: Consumer<UserProfileModel>(
        builder: (context, profile, _) {
          return NavigationDrawerPanel(onSelectDynamicTab: setDynamicTab);
        },
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          _tabController.animateTo(index);
        },
        children: [
          if (_dynamicTabContent != null) _dynamicTabContent!,
          HeroPanel(controller: contentController),
          VillagePanel(
            onVillageTap: (village) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => VillageCenterScreen(village: village),
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
    );
  }
}
