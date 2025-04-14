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
    final combatDoc = await FirebaseFirestore.instance
        .collection('combats')
        .doc(widget.combatId)
        .get();
    final data = combatDoc.data();
    final heroId = data?['heroIds']?[0];

    if (heroId != null) {
      final heroDoc = await FirebaseFirestore.instance
          .collection('heroes')
          .doc(heroId)
          .get();
      setState(() {
        heroName = heroDoc.data()?['heroName'] ?? 'Hero';
      });
    }
  }

  String _formatFullTimestamp(DateTime time) {
    return "${time.day.toString().padLeft(2, '0')}/"
        "${time.month.toString().padLeft(2, '0')}/"
        "${time.year} – "
        "${time.hour.toString().padLeft(2, '0')}:"
        "${time.minute.toString().padLeft(2, '0')}:"
        "${time.second.toString().padLeft(2, '0')}";
  }

  /// Builds the main combat UI given the combat document data and an optional event description.
  Widget _buildCombatLogUI(BuildContext context, Map<String, dynamic> combatData,
      {String? description}) {
    final xp = combatData['xp'];
    final message = combatData['message'];
    final finalHp = combatData['heroHpAfter'];
    final createdAt = (combatData['createdAt'] as Timestamp?)?.toDate();
    final endedAt = (combatData['endedAt'] as Timestamp?)?.toDate();
    final rewards = List<String>.from(combatData['reward'] ?? []);
    final enemyName = combatData['enemyName'] ?? 'Enemy';
    final state = combatData['state'];

    final combatDocRef =
    FirebaseFirestore.instance.collection('combats').doc(widget.combatId);
    final combatLogRef = combatDocRef.collection('combatLog').orderBy('tick');

    return StreamBuilder<QuerySnapshot>(
      stream: combatLogRef.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        // Scroll to bottom after a frame.
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

        // For summary display we get the last tick.
        final latestLog = docs.last.data() as Map<String, dynamic>?;
        final latestHeroHp = latestLog?['heroHpAfter'] as int?;
        final latestEnemiesHp =
        List<int>.from(latestLog?['enemiesHpAfter'] ?? []);

        return Column(
          children: [
            if (description != null)
              Container(
                width: double.infinity,
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.black.withOpacity(0.03),
                child: Text(
                  description,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontStyle: FontStyle.italic),
                ),
              ),
            if (createdAt != null || endedAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 12),
                child: Column(
                  children: [
                    if (createdAt != null)
                      Text(
                        "🕐 Combat started: ${_formatFullTimestamp(createdAt)}",
                        style: const TextStyle(
                            fontSize: 13, color: Colors.grey),
                      ),
                    if (endedAt != null)
                      Text(
                        "🏁 Combat ended: ${_formatFullTimestamp(endedAt)}",
                        style: const TextStyle(
                            fontSize: 13, color: Colors.grey),
                      ),
                  ],
                ),
              ),
            if (state == 'completed') ...[
              Card(
                color: Colors.green.shade100,
                margin: const EdgeInsets.all(12),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message != null) Text(message),
                      if (xp != null) Text("⭐ Gained XP: $xp"),
                      if (rewards.isNotEmpty)
                        Text("💰 Loot gained: ${rewards.join(', ')}"),
                      if (finalHp != null) Text("❤️ Final HP: $finalHp"),
                    ],
                  ),
                ),
              ),
            ],
            Container(
              width: double.infinity,
              margin:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Card(
                color: Colors.blueGrey.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("📋 Combat Summary",
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium),
                      const SizedBox(height: 8),
                      Text("🧙 Heroes:",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold)),
                      Text(
                          "${heroName ?? 'Hero'} (${latestHeroHp ?? '?'} HP remaining)"),
                      const SizedBox(height: 8),
                      Text("👹 Enemies:",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold)),
                      if (latestEnemiesHp.isEmpty)
                        const Text("None remaining.")
                      else
                        ...List.generate(latestEnemiesHp.length, (i) {
                          final hp = latestEnemiesHp[i];
                          return Text("$enemyName #$i (${hp} HP remaining)");
                        }),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data()
                  as Map<String, dynamic>;

                  // Variables for enemy attacks and timestamps
                  final enemyAttacks = List<Map<String, dynamic>>.from(
                      data['enemyAttacks'] ?? []);
                  final timestamp =
                  (data['timestamp'] as Timestamp?)?.toDate();
                  final timeString = timestamp != null
                      ? "${timestamp.hour.toString().padLeft(2, '0')}:"
                      "${timestamp.minute.toString().padLeft(2, '0')}:"
                      "${timestamp.second.toString().padLeft(2, '0')}"
                      : '';

                  // Build the hero attack widget.
                  Widget heroAttackWidget = const SizedBox.shrink();

                  // Check if we have PvP logs with multiple hero attacks.
                  if (data.containsKey('heroAttacks') &&
                      data['heroAttacks'] is List) {
                    final List heroAttacks = data['heroAttacks'] as List;
                    List<Widget> attackWidgets = [];
                    for (final attack in heroAttacks) {
                      if (attack is Map) {
                        final attackerId =
                            attack['attackerId']?.toString() ?? '';
                        final targetType =
                            attack['targetType']?.toString() ?? '';
                        final target = attack['target'];
                        final damage =
                            attack['damage']?.toString() ?? '';
                        String targetText = "";
                        if (targetType == 'enemy' && target is int) {
                          final enemyHp = (data['enemiesHpAfter'] is List &&
                              (data['enemiesHpAfter'] as List)
                                  .isNotEmpty &&
                              target <
                                  (data['enemiesHpAfter'] as List)
                                      .length)
                              ? (data['enemiesHpAfter'] as List)[target]
                              : '?';
                          targetText =
                          "$enemyName #$target ($enemyHp HP remaining)";
                        } else if (targetType == 'hero' && target is String) {
                          // For hero targets, try to get their remaining HP from heroesHpAfter mapping.
                          final heroesHpAfter = data['heroesHpAfter'] is Map
                              ? (data['heroesHpAfter'] as Map)
                              : null;
                          final targetHp = heroesHpAfter != null &&
                              heroesHpAfter.containsKey(target)
                              ? heroesHpAfter[target]
                              : '?';
                          targetText =
                          "$target ($targetHp HP remaining)";
                        } else {
                          targetText = "$target";
                        }
                        attackWidgets.add(
                          RichText(
                            text: TextSpan(
                              style: DefaultTextStyle.of(context).style,
                              children: [
                                const TextSpan(text: "🧙 "),
                                TextSpan(
                                  text: "$attackerId",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                const TextSpan(text: " hits "),
                                TextSpan(
                                  text: targetText,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                TextSpan(
                                    text: " for $damage damage."),
                              ],
                            ),
                          ),
                        );
                      }
                    }
                    heroAttackWidget = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: attackWidgets,
                    );
                  }
                  // Fallback to legacy PvE log processing.
                  else if (data.containsKey('heroAttack') &&
                      data['heroAttack'] != null) {
                    final dynamic heroAttackRaw = data['heroAttack'];
                    final targetEnemy = data['targetEnemyIndex'];
                    final heroHpAfter = data['heroHpAfter'];
                    if (heroAttackRaw is Map) {
                      final attackerId =
                          heroAttackRaw['attackerId']?.toString() ?? '';
                      final targetType =
                          heroAttackRaw['targetType']?.toString() ?? '';
                      final target = heroAttackRaw['target'];
                      final damage =
                          heroAttackRaw['damage']?.toString() ?? '';
                      String targetText = "";
                      if (targetType == 'enemy' && target is int) {
                        final enemyHp = (data['enemiesHpAfter'] is List &&
                            (data['enemiesHpAfter'] as List)
                                .isNotEmpty &&
                            target <
                                (data['enemiesHpAfter'] as List)
                                    .length)
                            ? (data['enemiesHpAfter'] as List)[target]
                            : '?';
                        targetText =
                        "$enemyName #$target ($enemyHp HP remaining)";
                      } else if (targetType == 'hero') {
                        targetText = "$target";
                      }
                      heroAttackWidget = RichText(
                        text: TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: [
                            const TextSpan(text: "🧙 "),
                            TextSpan(
                              text: "$attackerId",
                              style:
                              const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const TextSpan(text: " hits "),
                            TextSpan(
                              text: targetText,
                              style:
                              const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                                text: " for $damage damage."),
                          ],
                        ),
                      );
                    } else if (heroAttackRaw is int &&
                        heroAttackRaw > 0 &&
                        targetEnemy != null) {
                      heroAttackWidget = RichText(
                        text: TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: [
                            const TextSpan(text: "🧙 "),
                            TextSpan(
                              text: heroName ?? 'Hero',
                              style:
                              const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const TextSpan(text: " hits "),
                            TextSpan(
                              text: "$enemyName #$targetEnemy",
                              style:
                              const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                                text:
                                " for $heroAttackRaw damage → ${(data['enemiesHpAfter'] is List && (data['enemiesHpAfter'] as List).isNotEmpty ? (data['enemiesHpAfter'] as List)[targetEnemy] : '?')} HP remaining."),
                          ],
                        ),
                      );
                    }
                  }

                  // Build enemy attacks widget.
                  List<Widget> enemyAttackWidgets = [];
                  final heroHpAfterForEnemy = data['heroHpAfter'];
                  for (final attack in enemyAttacks) {
                    if (heroHpAfterForEnemy != null) {
                      enemyAttackWidgets.add(
                        RichText(
                          text: TextSpan(
                            style: DefaultTextStyle.of(context).style,
                            children: [
                              const TextSpan(text: "👹 "),
                              TextSpan(
                                text: "$enemyName #${attack['index']}",
                                style:
                                const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const TextSpan(text: " strikes "),
                              TextSpan(
                                text: heroName ?? 'Hero',
                                style:
                                const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text:
                                " for ${attack['damage']} damage → $heroHpAfterForEnemy HP remaining.",
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  }

                  // Only render a log card if there is at least one attack recorded.
                  final nothingHappened =
                  ((data.containsKey('heroAttack') &&
                      (data['heroAttack'] is int &&
                          data['heroAttack'] == 0)) ||
                      (!data.containsKey('heroAttack') &&
                          (!data.containsKey('heroAttacks') ||
                              (data['heroAttacks'] is List &&
                                  (data['heroAttacks'] as List)
                                      .isEmpty))) &&
                          enemyAttackWidgets.isEmpty);
                  if (nothingHappened) {
                    return const SizedBox.shrink();
                  }

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
                            if (timeString.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text(
                                  timeString,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            // Show the attack logs.
                            heroAttackWidget,
                            ...enemyAttackWidgets,
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final combatDocRef =
    FirebaseFirestore.instance.collection('combats').doc(widget.combatId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Combat Log'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: combatDocRef.get(),
        builder: (context, combatSnapshot) {
          if (!combatSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final combatData =
          combatSnapshot.data!.data() as Map<String, dynamic>?;
          if (combatData == null) {
            return const Center(child: Text("Combat not found."));
          }

          final eventId = combatData['eventId'] as String?;

          if (eventId == null) {
            // If there's no eventId, simply build the UI without fetching event data.
            return _buildCombatLogUI(context, combatData, description: null);
          } else {
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('encounterEvents')
                  .doc(eventId)
                  .get(),
              builder: (context, eventSnapshot) {
                if (eventSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (eventSnapshot.hasError) {
                  return Text('Error: ${eventSnapshot.error}');
                }
                final eventDoc = eventSnapshot.data;
                String? description;
                if (eventDoc != null && eventDoc.exists) {
                  final eventData =
                  eventDoc.data() as Map<String, dynamic>?;
                  description = eventData?['description'] as String?;
                }
                return _buildCombatLogUI(context, combatData, description: description);
              },
            );
          }
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
