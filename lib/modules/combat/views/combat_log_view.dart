import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CombatLogView extends StatefulWidget {
  final String combatId;

  const CombatLogView({super.key, required this.combatId});

  @override
  State<CombatLogView> createState() => _CombatLogViewState();
}

class _CombatLogViewState extends State<CombatLogView> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final combatDocRef = FirebaseFirestore.instance.collection('combats').doc(widget.combatId);

    return FutureBuilder<DocumentSnapshot>(
      future: combatDocRef.get(),
      builder: (context, combatSnapshot) {
        if (!combatSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final combatData = combatSnapshot.data!.data() as Map<String, dynamic>?;
        if (combatData == null) {
          return const Center(child: Text("Combat not found."));
        }

        // 🧠 Extract hero name map from the combat document
        final List<dynamic> heroList = combatData['heroes'] ?? [];
        final Map<String, String> heroNameMap = {
          for (var hero in heroList)
            if (hero is Map && hero['refPath'] is String)
              (hero['refPath'] as String).split('/').last: hero['name'] ?? 'Hero'
        };

        final eventId = combatData['eventId'] as String?;

        return FutureBuilder<DocumentSnapshot>(
          future: eventId != null
              ? FirebaseFirestore.instance.collection('encounterEvents').doc(eventId).get()
              : Future.value(null),
          builder: (context, eventSnapshot) {
            if (eventSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final eventDoc = eventSnapshot.data;
            String? description;
            if (eventDoc != null && eventDoc.exists) {
              final eventData = eventDoc.data() as Map<String, dynamic>?;
              description = eventData?['description'] as String?;
            }

            return _buildCombatLogUI(heroNameMap, description);
          },
        );
      },
    );
  }

  Widget _buildCombatLogUI(Map<String, String> heroNameMap, String? description) {
    final combatLogRef = FirebaseFirestore.instance
        .collection('combats')
        .doc(widget.combatId)
        .collection('combatLog')
        .orderBy('tick');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (description != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            color: Colors.black.withAlpha(15),
            child: Text(
              description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic),
            ),
          ),
        const Text("⚔️ Combat Log", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: Colors.grey.shade100,
          ),
          child: StreamBuilder<QuerySnapshot>(
            stream: combatLogRef.snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final docs = snapshot.data!.docs.reversed.toList(); // 🧠 latest tick first

              if (docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text("No combat log entries."),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final time = (data['timestamp'] as Timestamp?)?.toDate();
                  final heroAttacks = List<Map<String, dynamic>>.from(data['heroAttacks'] ?? []);
                  final enemyAttacks = List<Map<String, dynamic>>.from(data['enemyAttacks'] ?? []);
                  final enemiesHp = List<int>.from(data['enemiesHpAfter'] ?? []);
                  final heroesHp = Map<String, dynamic>.from(data['heroesHpAfter'] ?? {});

                  if (heroAttacks.isEmpty && enemyAttacks.isEmpty) {
                    return const SizedBox.shrink(); // 🔕 Skip boring ticks
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (time != null)
                              Text(
                                "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}",
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            const SizedBox(height: 6),

                            // 🧙 Hero Attacks
                            ...heroAttacks.map((attack) {
                              final attackerId = attack['attackerId']?.toString() ?? '';
                              final attackerName = heroNameMap[attackerId] ?? attackerId;
                              final targetIndex = attack['targetIndex'];
                              final damage = attack['damage'];
                              final hpLeft = (targetIndex is int && targetIndex < enemiesHp.length)
                                  ? enemiesHp[targetIndex]
                                  : '?';
                              return Text(
                                "🧙 $attackerName hits 👹 Enemy #$targetIndex for $damage dmg → $hpLeft HP left",
                              );
                            }),

                            // 👹 Enemy Attacks
                            ...enemyAttacks.map((e) {
                              final heroId = e['heroId']?.toString();
                              final enemyIndex = e['enemyIndex'];
                              final heroName = heroNameMap[heroId] ?? heroId ?? '?';
                              final damage = e['damage'];
                              final hpLeft = heroesHp[heroId] ?? '?';
                              return Text(
                                "👹 Enemy #$enemyIndex hits 🧙 $heroName for $damage dmg → $hpLeft HP left",
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
