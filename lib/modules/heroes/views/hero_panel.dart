import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:roots_app/modules/heroes/views/create_main_hero_screen.dart';
import 'package:roots_app/modules/heroes/views/create_companion_screen.dart';
import 'package:roots_app/modules/heroes/views/hero_details_screen.dart';
import 'package:roots_app/modules/heroes/widgets/hero_card.dart';
import 'package:roots_app/modules/heroes/models/hero_model.dart';
import 'package:roots_app/screens/controllers/main_content_controller.dart';
import 'package:roots_app/modules/profile/views/player_profile_screen.dart';
import 'package:roots_app/modules/profile/views/guild_profile_screen.dart';
import 'package:roots_app/modules/profile/views/alliance_profile_screen.dart';

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
    return StreamBuilder<List<HeroModel>>(
      stream: _heroStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final heroes = snapshot.data!;

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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Welcome, adventurer!\nLet’s start by creating your Main Hero (Mage).',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.person_add),
                  onPressed: () {
                    controller.setCustomContent(const CreateMainHeroScreen());
                  },
                  label: const Text('Create Main Hero'),
                ),
              ],
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
            final currentMaxSlots = profile?['currentMaxSlots'] ?? (limits['maxSlots'] ?? 0);
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
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (allianceTag != null && allianceId != null)
                        GestureDetector(
                          onTap: () {
                            controller.setCustomContent(
                              AllianceProfileScreen(allianceId: allianceId),
                            );
                          },
                          child: Text(
                            '[$allianceTag] ',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.teal,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      if (guildTag != null && guildId != null)
                        GestureDetector(
                          onTap: () {
                            controller.setCustomContent(
                              GuildProfileScreen(guildId: guildId),
                            );
                          },
                          child: Text(
                            '[$guildTag] ',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      GestureDetector(
                        onTap: () {
                          final isMobile = MediaQuery.of(context).size.width < 1024;
                          if (isMobile) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PlayerProfileScreen(userId: uid),
                              ),
                            );
                          } else {
                            controller.setPlayerProfileScreen(uid);
                          }
                        },
                        child: Text(
                          heroName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.deepPurple,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: heroes.length,
                    itemBuilder: (context, index) {
                      final hero = heroes[index];
                      final isMobile = MediaQuery.of(context).size.width < 1024;

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
                            controller.setCustomContent(HeroDetailsScreen(hero: hero));
                          }
                        },
                      );
                    },
                  ),
                ),
                if (canAddCompanion)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        controller.setCustomContent(const CreateCompanionScreen());
                      },
                      icon: const Icon(Icons.add),
                      label: const Text("Create Companion"),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Slots used: $usedTotal / $currentMaxSlots",
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 2),
                      Text("Companions: $usedCompanions",
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      Text("Villages: $usedVillages",
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            );
          },
        );
      },
    );
  }
}
