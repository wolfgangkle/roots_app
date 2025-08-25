import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Models & tabs
import 'package:roots_app/modules/heroes/models/hero_model.dart';
import 'package:roots_app/modules/heroes/views/details_tabs/hero_stats_tab.dart';
import 'package:roots_app/modules/heroes/views/details_tabs/hero_equipment_tab.dart';
import 'package:roots_app/modules/heroes/views/details_tabs/hero_resources_tab.dart';
import 'package:roots_app/modules/heroes/views/details_tabs/hero_settings_tab.dart';
import 'package:roots_app/modules/heroes/views/details_tabs/hero_group_tab.dart';
import 'package:roots_app/modules/heroes/views/details_tabs/hero_spellbook_tab.dart';

// 🔷 Tokens
import 'package:provider/provider.dart';
import 'package:roots_app/theme/app_style_manager.dart';
import 'package:roots_app/theme/widgets/token_panels.dart';

class HeroDetailsScreen extends StatelessWidget {
  final HeroModel hero;

  const HeroDetailsScreen({required this.hero, super.key});

  @override
  Widget build(BuildContext context) {
    // Tokenized styling hooks
    context.watch<StyleManager>();
    final glass = kStyle.glass;
    final text = kStyle.textOnGlass;
    final cardPad = kStyle.card.padding;

    final heroId = hero.id;
    final isMobile = MediaQuery.of(context).size.width < 1024;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('heroes').doc(heroId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final heroData = snapshot.data!.data() as Map<String, dynamic>?;
        if (heroData == null) {
          return const Scaffold(body: Center(child: Text('Hero not found.')));
        }

        final currentHero = HeroModel.fromFirestore(heroId, heroData);
        final groupId = currentHero.groupId;

        if (groupId == null) {
          return const Scaffold(body: Center(child: Text('⚠️ This hero has no group.')));
        }

        final groupRef = FirebaseFirestore.instance.collection('heroGroups').doc(groupId);

        return StreamBuilder<DocumentSnapshot>(
          stream: groupRef.snapshots(),
          builder: (context, groupSnapshot) {
            if (!groupSnapshot.hasData || !groupSnapshot.data!.exists) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            final groupData = groupSnapshot.data!.data() as Map<String, dynamic>;
            final tileX = groupData['tileX'] ?? 0;
            final tileY = groupData['tileY'] ?? 0;
            final insideVillage = groupData['insideVillage'] ?? false;

            final bool isMage = currentHero.type == 'mage';

            return DefaultTabController(
              length: isMage ? 6 : 5,
              child: Scaffold(
                backgroundColor: Colors.transparent,
                extendBody: true,
                appBar: AppBar(
                  backgroundColor: Colors.transparent,
                  title: Text(currentHero.heroName),
                  automaticallyImplyLeading: isMobile,
                  // Put the TabBar inside a token "box" as the app bar bottom
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(80), // header row + tabs
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Small header info (location, state) in a box
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            cardPad.left,
                            8,
                            cardPad.right,
                            6,
                          ),
                          child: TokenPanel(
                            glass: glass,
                            text: text,
                            padding: EdgeInsets.symmetric(
                              horizontal: cardPad.horizontal / 2,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Tile: ($tileX, $tileY) • ${insideVillage ? "Inside village" : "In the wilds"}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: text.secondary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Tabs themselves in a box
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            cardPad.left,
                            0,
                            cardPad.right,
                            8,
                          ),
                          child: TokenPanel(
                            glass: glass,
                            text: text,
                            padding: EdgeInsets.symmetric(
                              horizontal: cardPad.horizontal / 2,
                              vertical: 4,
                            ),
                            child: TabBar(
                              isScrollable: true,
                              labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                              labelColor: text.primary,
                              unselectedLabelColor: text.secondary,
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
                        ),
                      ],
                    ),
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
