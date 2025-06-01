import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:roots_app/modules/heroes/models/hero_model.dart';
import 'package:roots_app/modules/heroes/views/details_tabs/hero_stats_tab.dart';
import 'package:roots_app/modules/heroes/views/details_tabs/hero_equipment_tab.dart';
import 'package:roots_app/modules/heroes/views/details_tabs/hero_resources_tab.dart';
import 'package:roots_app/modules/heroes/views/details_tabs/hero_settings_tab.dart';
import 'package:roots_app/modules/heroes/views/details_tabs/hero_group_tab.dart';
import 'package:roots_app/modules/heroes/views/details_tabs/hero_spellbook_tab.dart'; // 🧙 NEW

class HeroDetailsScreen extends StatelessWidget {
  final HeroModel hero;

  const HeroDetailsScreen({required this.hero, super.key});

  @override
  Widget build(BuildContext context) {
    final heroId = hero.id;
    final isMobile = MediaQuery.of(context).size.width < 1024;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('heroes')
          .doc(heroId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final heroData = snapshot.data!.data() as Map<String, dynamic>?;
        if (heroData == null) {
          return const Scaffold(
            body: Center(child: Text("Hero not found.")),
          );
        }

        final currentHero = HeroModel.fromFirestore(heroId, heroData);
        final groupId = currentHero.groupId;

        if (groupId == null) {
          return const Scaffold(
            body: Center(child: Text("⚠️ This hero has no group.")),
          );
        }

        final groupRef =
            FirebaseFirestore.instance.collection('heroGroups').doc(groupId);

        return StreamBuilder<DocumentSnapshot>(
          stream: groupRef.snapshots(),
          builder: (context, groupSnapshot) {
            if (!groupSnapshot.hasData || !groupSnapshot.data!.exists) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final groupData = groupSnapshot.data!.data() as Map<String, dynamic>;
            final tileX = groupData['tileX'] ?? 0;
            final tileY = groupData['tileY'] ?? 0;
            final insideVillage = groupData['insideVillage'] ?? false;

            final bool isMage = currentHero.type == 'mage'; // ✅ FIXED HERE

            return DefaultTabController(
              length: isMage ? 6 : 5,
              child: Scaffold(
                appBar: AppBar(
                  title: Text(currentHero.heroName),
                  automaticallyImplyLeading: isMobile,
                  bottom: TabBar(
                    tabs: [
                      const Tab(text: 'Stats'),
                      const Tab(text: 'Equipment'),
                      const Tab(text: 'Resources'),
                      const Tab(text: 'Hero Settings'),
                      const Tab(text: 'Groups'),
                      if (isMage) const Tab(text: 'Spellbook'),
                    ],
                  ),
                ),
                body: TabBarView(
                  children: [
                    HeroStatsTab(hero: currentHero),
                    HeroEquipmentTab(
                      heroId: currentHero.id,
                      tileX: tileX,
                      tileY: tileY,
                      insideVillage: insideVillage,
                    ),
                    HeroResourcesTab(hero: currentHero),
                    const HeroSettingsTab(),
                    HeroGroupsTab(hero: currentHero),
                    if (isMage)
                      HeroSpellbookTab(
                        heroId: currentHero.id,
                        userId: currentHero.ownerId,
                        tileX: tileX,
                        tileY: tileY,
                        insideVillage: insideVillage,
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
