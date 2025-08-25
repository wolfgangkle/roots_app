import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'package:roots_app/modules/heroes/views/create_main_hero_screen.dart';
import 'package:roots_app/modules/heroes/views/create_companion_screen.dart';
import 'package:roots_app/modules/heroes/views/hero_details_screen.dart';
import 'package:roots_app/modules/heroes/widgets/hero_card.dart';
import 'package:roots_app/modules/heroes/models/hero_model.dart';
import 'package:roots_app/screens/controllers/main_content_controller.dart';
import 'package:roots_app/modules/profile/views/player_profile_screen.dart';
import 'package:roots_app/modules/profile/views/guild_profile_screen.dart';
import 'package:roots_app/modules/profile/views/alliance_profile_screen.dart';

// 🔷 Tokens
import 'package:roots_app/theme/app_style_manager.dart';
import 'package:roots_app/theme/widgets/token_panels.dart';
import 'package:roots_app/theme/widgets/token_buttons.dart';

class HeroPanel extends StatelessWidget {
  final MainContentController controller;

  const HeroPanel({required this.controller, super.key});

  Stream<List<HeroModel>> _heroStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('heroes')
        .where('ownerId', isEqualTo: user.uid)
        .snapshots()
        .map((query) => query.docs.map((doc) {
      return HeroModel.fromFirestore(doc.id, doc.data());
    }).toList());
  }

  Future<Map<String, dynamic>?> _loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('profile')
        .doc('main')
        .get();

    return doc.data();
  }

  @override
  Widget build(BuildContext context) {
    // 🔁 Live-reactive to theme switches
    context.watch<StyleManager>();
    final glass = kStyle.glass;
    final text = kStyle.textOnGlass;
    final buttons = kStyle.buttons;
    final cardPad = kStyle.card.padding;

    return StreamBuilder<List<HeroModel>>(
      stream: _heroStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final heroes = [...snapshot.data!];

        // Sort: mage first, then companions by createdAt
        heroes.sort((a, b) {
          if (a.type == 'mage' && b.type != 'mage') return -1;
          if (b.type == 'mage' && a.type != 'mage') return 1;
          final aTime = a.createdAt?.millisecondsSinceEpoch ?? 0;
          final bTime = b.createdAt?.millisecondsSinceEpoch ?? 0;
          return aTime.compareTo(bTime);
        });

        final hasMainHero = heroes.any((h) => h.type == 'mage');

        if (!hasMainHero) {
          // 🧙 Empty state (no mage yet)
          return Center(
            child: TokenPanel(
              glass: glass,
              text: text,
              padding: cardPad,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Welcome, adventurer!\nLet’s start by creating your Main Hero (Mage).',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: text.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TokenButton(
                    glass: glass,
                    text: text,
                    buttons: buttons,
                    variant: TokenButtonVariant.primary,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.person_add),
                        SizedBox(width: 8),
                        Text('Create Main Hero'),
                      ],
                    ),
                    onPressed: () {
                      controller.setCustomContent(const CreateMainHeroScreen());
                    },
                  ),
                ],
              ),
            ),
          );
        }

        return FutureBuilder<Map<String, dynamic>?>(
          future: _loadProfile(),
          builder: (context, profileSnap) {
            final profile = profileSnap.data;
            final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

            final current = profile?['currentSlotUsage'] ?? {};
            final limits = profile?['slotLimits'] ?? {};

            final usedCompanions = current['companions'] ?? 0;
            final usedVillages = current['villages'] ?? 0;
            final maxCompanions = limits['maxCompanions'] ?? 0;
            final currentMaxSlots =
                profile?['currentMaxSlots'] ?? (limits['maxSlots'] ?? 0);
            final usedTotal = usedCompanions + usedVillages;

            final canAddCompanion =
                usedTotal < currentMaxSlots && usedCompanions < maxCompanions;

            final allianceTag = profile?['allianceTag'];
            final allianceId = profile?['allianceId'];
            final guildTag = profile?['guildTag'];
            final guildId = profile?['guildId'];
            final heroName = profile?['heroName'] ?? 'Unnamed Hero';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 🔖 Header: Alliance / Guild / Player — now boxed
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    cardPad.left,
                    cardPad.top,
                    cardPad.right,
                    8,
                  ),
                  child: TokenPanel(
                    glass: glass,
                    text: text,
                    padding: EdgeInsets.symmetric(
                      horizontal: cardPad.horizontal / 2,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (allianceTag != null && allianceId != null)
                          TokenTextButton(
                            glass: glass,
                            text: text,
                            buttons: buttons,
                            variant: TokenButtonVariant.ghost,
                            onPressed: () {
                              controller.setCustomContent(
                                AllianceProfileScreen(allianceId: allianceId),
                              );
                            },
                            child: Text(
                              '[$allianceTag]',
                              style: TextStyle(
                                fontSize: 16,
                                color: text.secondary,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        if (guildTag != null && guildId != null)
                          TokenTextButton(
                            glass: glass,
                            text: text,
                            buttons: buttons,
                            variant: TokenButtonVariant.ghost,
                            onPressed: () {
                              controller.setCustomContent(
                                GuildProfileScreen(guildId: guildId),
                              );
                            },
                            child: Text(
                              ' [$guildTag] ',
                              style: TextStyle(
                                fontSize: 16,
                                color: text.secondary,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        TokenTextButton(
                          glass: glass,
                          text: text,
                          buttons: buttons,
                          variant: TokenButtonVariant.ghost,
                          onPressed: () {
                            final isMobile =
                                MediaQuery.of(context).size.width < 1024;
                            if (isMobile) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      PlayerProfileScreen(userId: uid),
                                ),
                              );
                            } else {
                              controller.setPlayerProfileScreen(uid);
                            }
                          },
                          child: Text(
                            heroName,
                            style: TextStyle(
                              fontSize: 16,
                              color: text.primary,
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── List of heroes
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: heroes.length,
                    itemBuilder: (context, index) {
                      final hero = heroes[index];
                      final isMobile =
                          MediaQuery.of(context).size.width < 1024;

                      return HeroCard(
                        hero: hero,
                        onTap: () {
                          if (isMobile) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => HeroDetailsScreen(hero: hero),
                              ),
                            );
                          } else {
                            controller
                                .setCustomContent(HeroDetailsScreen(hero: hero));
                          }
                        },
                      );
                    },
                  ),
                ),

                // ── Create companion (if allowed)
                if (canAddCompanion) ...[
                  TokenDivider(glass: glass, text: text),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: cardPad.horizontal / 2,
                      vertical: 8,
                    ),
                    child: TokenButton(
                      glass: glass,
                      text: text,
                      buttons: buttons,
                      variant: TokenButtonVariant.primary,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.add),
                          SizedBox(width: 8),
                          Text('Create Companion'),
                        ],
                      ),
                      onPressed: () {
                        controller
                            .setCustomContent(const CreateCompanionScreen());
                      },
                    ),
                  ),
                ],

                // ── Bottom split: Slots (left) + Graveyard (right), both boxed and side‑by‑side (when space allows)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    cardPad.left,
                    4,
                    cardPad.right,
                    cardPad.bottom,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Side‑by‑side unless it’s really tiny
                      final isNarrow = constraints.maxWidth < 360;

                      final panelLeft = TokenPanel(
                        glass: glass,
                        text: text,
                        padding: EdgeInsets.fromLTRB(
                          cardPad.left / 2, 8, cardPad.right / 2, 8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Slots used',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: text.primary),
                            ),
                            const SizedBox(height: 6),
                            Text('Total: $usedTotal / $currentMaxSlots', style: TextStyle(fontSize: 12, color: text.subtle)),
                            Text('Companions: $usedCompanions', style: TextStyle(fontSize: 12, color: text.subtle)),
                            Text('Villages: $usedVillages', style: TextStyle(fontSize: 12, color: text.subtle)),
                          ],
                        ),
                      );

                      final panelRightCore = TokenPanel(
                        glass: glass,
                        text: text,
                        padding: EdgeInsets.fromLTRB(
                          cardPad.left / 2, 8, cardPad.right / 2, 8,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Graveyard',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: text.primary),
                                ),
                                const SizedBox(height: 6),
                                Text('Revive fallen heroes\n(coming soon)',
                                  style: TextStyle(fontSize: 12, color: text.subtle),
                                ),
                              ],
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                      );

                      final panelRight = GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          // TODO: hook up to your real Graveyard screen
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Graveyard coming soon', style: TextStyle(color: text.primary)),
                              backgroundColor: glass.baseColor.withValues(alpha: glass.opacity),
                            ),
                          );
                        },
                        child: panelRightCore,
                      );

                      if (isNarrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            panelLeft,
                            const SizedBox(height: 12),
                            panelRight,
                          ],
                        );
                      }

                      return Row(
                        // ✅ don’t stretch vertically in an unbounded Column
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: panelLeft),
                          const SizedBox(width: 12),
                          Expanded(child: panelRight),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
