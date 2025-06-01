import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roots_app/modules/spells/data/spell_data.dart';
import 'package:roots_app/modules/heroes/widgets/available_spell_card.dart';
import 'package:roots_app/modules/heroes/widgets/learned_spell_card.dart';

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
            allSpells,
            learnedSpells,
            {},
            heroRace,
            insideVillage: false,
            heroId: heroId,
            userId: userId,
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

            final villageDoc = villageSnap.data!.docs.firstOrNull;
            final villageData = villageDoc?.data() as Map<String, dynamic>?;

            final rawUnlockedMap = (villageData?['spellsUnlocked'] as Map?) ?? {};
            final unlockedSpells = rawUnlockedMap.map((k, v) => MapEntry(k.toString(), v == true));


            return _buildSpellSections(
              allSpells,
              learnedSpells,
              unlockedSpells,
              heroRace,
              insideVillage: true,
              heroId: heroId,
              userId: userId,
            );
          },
        );
      },
    );
  }

  Widget _buildSpellSections(
      List<Map<String, dynamic>> spellList,
      List<String> learnedSpellIds,
      Map<String, bool> unlockedSpells,
      String heroRace, {
        required bool insideVillage,
        required String heroId,
        required String userId,
      }) {
    final filteredSpells = spellList.where((data) {
      final availableToAll = data['availableToAllRaces'] == true;
      final allowedRaces = List<String>.from(data['availableToRaces'] ?? []);
      return availableToAll || allowedRaces.contains(heroRace);
    }).toList();

    final learned = filteredSpells.where((s) => learnedSpellIds.contains(s['id'])).toList();
    final available = filteredSpells.where((s) => !learnedSpellIds.contains(s['id'])).toList();

    final infoWidget = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              insideVillage
                  ? (unlockedSpells.isEmpty
                  ? 'Build the Academy of Arts to unlock spells.'
                  : 'Unlocked spells can be learned here.')
                  : 'Visit a village to learn unlocked spells.',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
        ],
      ),
    );

    return Column(
      children: [
        infoWidget,
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  '📖 Learned Spells',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              if (learned.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'No spells learned yet. Visit a village to learn your first spell.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                ...learned.map((spell) => LearnedSpellCard(
                  spell: spell,
                  heroId: heroId,
                  userId: userId,
                )),


              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  '✨ Available Spells',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
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
    );
  }
}
