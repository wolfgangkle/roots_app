import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:roots_app/modules/spells/data/spell_data.dart';
import 'package:roots_app/modules/heroes/widgets/available_spell_card.dart';
import 'package:roots_app/modules/heroes/widgets/learned_spell_card.dart';

// 🔷 Tokens
import 'package:provider/provider.dart';
import 'package:roots_app/theme/app_style_manager.dart';
import 'package:roots_app/theme/widgets/token_panels.dart';
import 'package:roots_app/theme/tokens.dart';

class HeroSpellbookTab extends StatelessWidget {
  final String heroId;
  final String userId;
  final int tileX;
  final int tileY;
  final bool insideVillage;

  const HeroSpellbookTab({
    super.key,
    required this.heroId,
    required this.userId,
    required this.tileX,
    required this.tileY,
    required this.insideVillage,
  });

  @override
  Widget build(BuildContext context) {
    // 🔁 Tokens
    context.watch<StyleManager>();
    final glass = kStyle.glass;
    final text = kStyle.textOnGlass;
    final pad = kStyle.card.padding;

    final heroRef = FirebaseFirestore.instance.doc('heroes/$heroId');

    return FutureBuilder<DocumentSnapshot>(
      future: heroRef.get(),
      builder: (context, heroSnap) {
        if (!heroSnap.hasData || !heroSnap.data!.exists) {
          return const Center(child: CircularProgressIndicator());
        }

        final heroData = heroSnap.data!.data() as Map<String, dynamic>;
        final learnedSpells = List<String>.from(heroData['learnedSpells'] ?? []);
        final heroRace = (heroData['race'] ?? '').toString().toLowerCase();
        final allSpells = spellData;

        if (!insideVillage) {
          return _buildSpellSections(
            context: context,
            spellList: allSpells,
            learnedSpellIds: learnedSpells,
            unlockedSpells: const {},
            heroRace: heroRace,
            insideVillage: false,
            heroId: heroId,
            userId: userId,
            glass: glass,
            text: text,
            pad: pad,
          );
        }

        final villageStream = FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('villages')
            .where('tileX', isEqualTo: tileX)
            .where('tileY', isEqualTo: tileY)
            .limit(1)
            .snapshots();

        return StreamBuilder<QuerySnapshot>(
          stream: villageStream,
          builder: (context, villageSnap) {
            if (!villageSnap.hasData || villageSnap.data!.docs.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            final villageDoc = villageSnap.data!.docs.first;
            final villageData = villageDoc.data() as Map<String, dynamic>?;

            final rawUnlockedMap = (villageData?['spellsUnlocked'] as Map?) ?? {};
            final unlockedSpells = rawUnlockedMap.map(
                  (k, v) => MapEntry(k.toString(), v == true),
            );

            return _buildSpellSections(
              context: context,
              spellList: allSpells,
              learnedSpellIds: learnedSpells,
              unlockedSpells: unlockedSpells,
              heroRace: heroRace,
              insideVillage: true,
              heroId: heroId,
              userId: userId,
              glass: glass,
              text: text,
              pad: pad,
            );
          },
        );
      },
    );
  }

  Widget _buildSpellSections({
    required BuildContext context,
    required List<Map<String, dynamic>> spellList,
    required List<String> learnedSpellIds,
    required Map<String, bool> unlockedSpells,
    required String heroRace,
    required bool insideVillage,
    required String heroId,
    required String userId,
    required GlassTokens glass,
    required TextOnGlassTokens text,
    required EdgeInsets pad,
  }) {
    final filteredSpells = spellList.where((data) {
      final availableToAll = data['availableToAllRaces'] == true;
      final allowedRaces = List<String>.from(data['availableToRaces'] ?? []);
      return availableToAll || allowedRaces.contains(heroRace);
    }).toList();

    final learned =
    filteredSpells.where((s) => learnedSpellIds.contains(s['id'])).toList();
    final available =
    filteredSpells.where((s) => !learnedSpellIds.contains(s['id'])).toList();

    final infoText = insideVillage
        ? (unlockedSpells.isEmpty
        ? 'Build the Academy of Arts to unlock spells.'
        : 'Unlocked spells can be learned here.')
        : 'Visit a village to learn unlocked spells.';

    return Padding(
      padding: EdgeInsets.fromLTRB(pad.left, pad.top, pad.right, pad.bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ℹ️ Context panel
          TokenPanel(
            glass: glass,
            text: text,
            padding: EdgeInsets.fromLTRB(pad.left, 12, pad.right, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: text.secondary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    infoText,
                    style: TextStyle(color: text.secondary),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Scrollable content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 4),
              children: [
                // 📖 Learned
                TokenPanel(
                  glass: glass,
                  text: text,
                  padding: EdgeInsets.fromLTRB(pad.left, 14, pad.right, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📖 Learned Spells',
                        style: TextStyle(
                          color: text.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (learned.isEmpty)
                        Text(
                          'No spells learned yet. Visit a village to learn your first spell.',
                          style: TextStyle(color: text.secondary),
                        )
                      else
                        ...learned.map(
                              (spell) => LearnedSpellCard(
                            spell: spell,
                            heroId: heroId,
                            userId: userId,
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ✨ Available
                TokenPanel(
                  glass: glass,
                  text: text,
                  padding: EdgeInsets.fromLTRB(pad.left, 14, pad.right, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '✨ Available Spells',
                        style: TextStyle(
                          color: text.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...available.map((spell) {
                        final id = spell['id'];
                        return AvailableSpellCard(
                          spell: spell,
                          isUnlocked: unlockedSpells[id] == true,
                          isLearned: false,
                          heroId: heroId,
                          userId: userId,
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
