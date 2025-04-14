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

  @override
  Widget build(BuildContext context) {
    final combatDocRef =
    FirebaseFirestore.instance.collection('combats').doc(widget.combatId);
    final combatLogRef = combatDocRef.collection('combatLog').orderBy('tick');

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

          final state = combatData['state'];
          final xp = combatData['xp'];
          final message = combatData['message'];
          final finalHp = combatData['heroHpAfter'];
          final eventId = combatData['eventId'] as String?;
          final createdAt =
          (combatData['createdAt'] as Timestamp?)?.toDate();
          final endedAt = (combatData['endedAt'] as Timestamp?)?.toDate();
          final rewards = List<String>.from(combatData['reward'] ?? []);
          final enemyName = combatData['enemyName'] ?? 'Enemy';

          return FutureBuilder<DocumentSnapshot>(
            future: eventId != null
                ? FirebaseFirestore.instance
                .collection('encounterEvents')
                .doc(eventId)
                .get()
                : Future.value(null),
            builder: (context, eventSnapshot) {
              final eventData =
              eventSnapshot.data?.data() as Map<String, dynamic>?;
              final description = eventData?['description'] as String?;

              return StreamBuilder<QuerySnapshot>(
                stream: combatLogRef.snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

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

                  final latestLog =
                  docs.last.data() as Map<String, dynamic>?;
                  final latestHeroHp = latestLog?['heroHpAfter'] as int?;
                  final latestEnemiesHp = List<int>.from(
                      latestLog?['enemiesHpAfter'] ?? []);

                  return Column(
                    children: [
                      if (description != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          color: Colors.black.withOpacity(0.03),
                          child: Text(
                            description,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                fontStyle: FontStyle.italic),
                          ),
                        ),
                      if (createdAt != null || endedAt != null)
                        Padding(
                          padding: const EdgeInsets.only(
                              top: 8, bottom: 12),
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
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                if (message != null) Text(message),
                                if (xp != null) Text("⭐ Gained XP: $xp"),
                                if (rewards.isNotEmpty)
                                  Text("💰 Loot gained: ${rewards.join(', ')}"),
                                if (finalHp != null)
                                  Text("❤️ Final HP: $finalHp"),
                              ],
                            ),
                          ),
                        ),
                      ],
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: Card(
                          color: Colors.blueGrey.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
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
                                    return Text(
                                        "$enemyName #$i (${hp} HP remaining)");
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
                            final heroAttackRaw = data['heroAttack'];
                            // For legacy logs, we also grab targetEnemyIndex
                            final targetEnemy = data['targetEnemyIndex'];
                            final heroHpAfter = data['heroHpAfter'];
                            final enemiesHpAfter = List<int>.from(
                                data['enemiesHpAfter'] ?? []);
                            final enemyAttacks =
                            List<Map<String, dynamic>>.from(
                                data['enemyAttacks'] ?? []);
                            final timestamp =
                            (data['timestamp'] as Timestamp?)?.toDate();
                            final timeString = timestamp != null
                                ? "${timestamp.hour.toString().padLeft(2, '0')}:"
                                "${timestamp.minute.toString().padLeft(2, '0')}:"
                                "${timestamp.second.toString().padLeft(2, '0')}"
                                : '';

                            // Build a widget for the hero attack log.
                            Widget heroAttackWidget = const SizedBox.shrink();
                            if (heroAttackRaw != null) {
                              if (heroAttackRaw is Map) {
                                final attackerId =
                                    heroAttackRaw['attackerId']?.toString() ?? '';
                                final targetType =
                                    heroAttackRaw['targetType']?.toString() ?? '';
                                final target =
                                heroAttackRaw['target'];
                                final damage =
                                    heroAttackRaw['damage']?.toString() ?? '';
                                String targetText = "";
                                if (targetType == 'enemy' &&
                                    target is int) {
                                  final enemyHp = (enemiesHpAfter.isNotEmpty &&
                                      target < enemiesHpAfter.length)
                                      ? enemiesHpAfter[target]
                                      : '?';
                                  targetText =
                                  "$enemyName #$target ($enemyHp HP remaining)";
                                } else if (targetType == 'hero') {
                                  targetText = "$target";
                                }
                                heroAttackWidget = RichText(
                                  text: TextSpan(
                                    style: DefaultTextStyle.of(context)
                                        .style,
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
                                          text:
                                          " for $damage damage."),
                                    ],
                                  ),
                                );
                              } else if (heroAttackRaw is int &&
                                  heroAttackRaw > 0 &&
                                  targetEnemy != null) {
                                heroAttackWidget = RichText(
                                  text: TextSpan(
                                    style: DefaultTextStyle.of(context)
                                        .style,
                                    children: [
                                      const TextSpan(text: "🧙 "),
                                      TextSpan(
                                        text: heroName ?? 'Hero',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const TextSpan(text: " hits "),
                                      TextSpan(
                                        text:
                                        "$enemyName #$targetEnemy",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      TextSpan(
                                          text:
                                          " for $heroAttackRaw damage → ${enemiesHpAfter.isNotEmpty ? enemiesHpAfter[targetEnemy] : '?'} HP remaining."),
                                    ],
                                  ),
                                );
                              }
                            }

                            // Build enemy attacks widget.
                            List<Widget> enemyAttackWidgets = [];
                            for (final attack in enemyAttacks) {
                              if (heroHpAfter != null) {
                                enemyAttackWidgets.add(
                                  RichText(
                                    text: TextSpan(
                                      style: DefaultTextStyle.of(context)
                                          .style,
                                      children: [
                                        const TextSpan(text: "👹 "),
                                        TextSpan(
                                          text:
                                          "$enemyName #${attack['index']}",
                                          style: const TextStyle(
                                              fontWeight:
                                              FontWeight.bold),
                                        ),
                                        const TextSpan(text: " strikes "),
                                        TextSpan(
                                          text:
                                          heroName ?? 'Hero',
                                          style: const TextStyle(
                                              fontWeight:
                                              FontWeight.bold),
                                        ),
                                        TextSpan(
                                          text:
                                          " for ${attack['damage']} damage → $heroHpAfter HP remaining.",
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                            }

                            // Skip rendering if nothing happened.
                            final nothingHappened = (heroAttackRaw == null ||
                                (heroAttackRaw is int && heroAttackRaw == 0)) &&
                                enemyAttacks.isEmpty;
                            if (nothingHappened) {
                              return const SizedBox.shrink();
                            }

                            return Padding(
                              padding:
                              const EdgeInsets.symmetric(vertical: 4),
                              child: Card(
                                color: Colors.grey.shade100,
                                elevation: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      if (timeString.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 6),
                                          child: Text(
                                            timeString,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                              fontWeight:
                                              FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      // Show detailed hero attack info.
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
