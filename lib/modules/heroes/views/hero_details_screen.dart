import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:roots_app/modules/heroes/models/hero_model.dart';
import 'package:roots_app/modules/heroes/views/details_tabs/hero_stats_tab.dart';
import 'package:roots_app/modules/heroes/views/details_tabs/hero_equipment_tab.dart';
import 'package:roots_app/modules/heroes/views/details_tabs/hero_resources_tab.dart';
import 'package:roots_app/modules/heroes/views/details_tabs/hero_settings_tab.dart';

class HeroDetailsScreen extends StatelessWidget {
  final HeroModel hero;

  const HeroDetailsScreen({required this.hero, super.key});

  @override
  Widget build(BuildContext context) {
    final heroId = hero.id;
    final isMobile = MediaQuery.of(context).size.width < 1024;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('heroes').doc(heroId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        if (data == null) {
          return const Scaffold(
            body: Center(child: Text("Hero not found.")),
          );
        }

        final currentHero = HeroModel.fromFirestore(heroId, data);

        return DefaultTabController(
          length: 4,
          child: Scaffold(
            appBar: AppBar(
              title: Text(currentHero.heroName),
              automaticallyImplyLeading: isMobile,
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Stats'),
                  Tab(text: 'Equipment'),
                  Tab(text: 'Resources'),
                  Tab(text: 'Hero Settings'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                HeroStatsTab(hero: currentHero),
                const HeroEquipmentTab(),
                HeroResourcesTab(hero: currentHero),
                const HeroSettingsTab(),
              ],
            ),
          ),
        );
      },
    );
  }
}
