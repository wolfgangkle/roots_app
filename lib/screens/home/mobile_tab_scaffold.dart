
import 'package:flutter/material.dart';
import 'panels/hero_panel.dart';
import 'panels/main_content_panel.dart';
import 'package:roots_app/modules/village/views/village_panel.dart';
import 'panels/chat_panel.dart';
import 'panels/navigation_drawer.dart';


class MobileTabScaffold extends StatefulWidget {
  const MobileTabScaffold({super.key});

  @override
  State<MobileTabScaffold> createState() => _MobileTabScaffoldState();
}

class _MobileTabScaffoldState extends State<MobileTabScaffold> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: 1);
    _pageController = PageController(initialPage: 1);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          tabs: const [
            Tab(text: '🧙 Heroes'),
            Tab(text: '🗺️ Main'),
            Tab(text: '🏰 Villages'),
            Tab(text: '💬 Chat'),
          ],
        ),
      ),
      drawer: const NavigationDrawerPanel(),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          _tabController.animateTo(index);
        },
        children: const [
          HeroPanel(),
          MainContentPanel(),
          VillagePanel(),
          ChatPanel(),
        ],
      ),
    );
  }
}
