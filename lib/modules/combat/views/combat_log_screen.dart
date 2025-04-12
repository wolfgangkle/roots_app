import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CombatLogScreen extends StatefulWidget {
  final String combatId;

  const CombatLogScreen({required this.combatId, super.key});

  @override
  State<CombatLogScreen> createState() => _CombatLogScreenState();
}

class _CombatLogScreenState extends State<CombatLogScreen> {
  final ScrollController _scrollController = ScrollController();
  String? heroName;

  @override
  void initState() {
    super.initState();
    _loadHeroName();
  }

  Future<void> _loadHeroName() async {
    final combatDoc = await FirebaseFirestore.instance.collection('combats').doc(widget.combatId).get();
    final data = combatDoc.data();
    final heroId = data?['heroIds']?[0];

    if (heroId != null) {
      final heroDoc = await FirebaseFirestore.instance.collection('heroes').doc(heroId).get();
      setState(() {
        heroName = heroDoc.data()?['heroName'] ?? 'Hero';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final combatLogRef = FirebaseFirestore.instance
        .collection('combats')
        .doc(widget.combatId)
        .collection('combatLog')
        .orderBy('tick');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Combat Log'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: combatLogRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          // Auto-scroll to bottom when new logs arrive
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });

          if (docs.isEmpty) {
            return const Center(child: Text("No combat log yet."));
          }

          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final tick = data['tick'] ?? '?';
              final heroAttack = data['heroAttack'] ?? 0;
              final enemyAttack = data['enemyAttack'] ?? 0;
              final targetEnemy = data['targetEnemyIndex'];
              final heroHpAfter = data['heroHpAfter'];
              final enemiesHpAfter = List<int>.from(data['enemiesHpAfter'] ?? []);

              // Skip ticks where nothing happened
              final nothingHappened = heroAttack == 0 && enemyAttack == 0;
              if (nothingHappened) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Card(
                  color: Colors.grey.shade100,
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("🌀 Tick $tick", style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),

                        if (heroAttack > 0 && targetEnemy != null) ...[
                          Text(
                            "🧙 ${heroName ?? 'Hero'} hits Bandit #$targetEnemy for $heroAttack damage "
                                "→ ${enemiesHpAfter.isNotEmpty ? enemiesHpAfter[targetEnemy] : '?'} HP remaining.",
                          ),
                        ],

                        if (enemyAttack > 0 && heroHpAfter != null) ...[
                          Text(
                            "👹 Enemies strike back → ${heroName ?? 'Hero'} takes $enemyAttack damage "
                                "→ ${heroHpAfter} HP remaining.",
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
