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
  String? heroName; // Used for single hero (PvE) cases

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

  /// Returns a TextSpan with the outcome text.
  /// If [hp] is 0, returns "[Target] died" in red bold text;
  /// otherwise returns "[hp] HP remaining".
  TextSpan _buildOutcomeSpan(dynamic hp, String targetName) {
    if (hp is int && hp == 0) {
      return TextSpan(
          text: "$targetName died",
          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold));
    } else {
      return TextSpan(text: "$hp HP remaining");
    }
  }

  /// Builds the combat log UI given the combat data, an optional event description,
  /// and (optionally) a mapping of hero IDs to hero names.
  Widget _buildCombatLogUIWithHeroMap(BuildContext context, Map<String, dynamic> combatData,
      {String? description, Map<String, String>? heroNameMap}) {
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
        // Retrieve the last log tick.
        final latestLog = docs.last.data() as Map<String, dynamic>?;

        // Determine if this is a PvP fight (multiple heroes) based on combatData.
        final bool isPvP = (combatData['heroIds'] is List) &&
            ((combatData['heroIds'] as List).length > 1);
        // For PvP, expect a map field 'heroesHpAfter' in the latest tick.
        Map<String, dynamic>? latestHeroesHpMap;
        if (isPvP) {
          latestHeroesHpMap = latestLog?['heroesHpAfter'] as Map<String, dynamic>?;
        }
        // For PvE, use 'heroHpAfter'.
        final latestHeroHp = latestLog?['heroHpAfter'] as int?;
        final latestEnemiesHp = List<int>.from(latestLog?['enemiesHpAfter'] ?? []);

        // Determine whether to show enemy summary.
        // We want to show enemy summary in pure PvE fights and in hybrid PvE/PvP fights (i.e. if an event is present)
        // but hide it in pure PvP fights.
        final bool showEnemySummary = (!isPvP) || (isPvP && combatData['eventId'] != null);

        return Column(
          children: [
            if (description != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        style:
                        const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    if (endedAt != null)
                      Text(
                        "🏁 Combat ended: ${_formatFullTimestamp(endedAt)}",
                        style:
                        const TextStyle(fontSize: 13, color: Colors.grey),
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
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Card(
                color: Colors.blueGrey.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("📋 Combat Summary", style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text("🧙 Heroes:", style: const TextStyle(fontWeight: FontWeight.bold)),
                      // PvP summary: display each hero with remaining HP or "(killed)".
                      if (isPvP && latestHeroesHpMap != null && heroNameMap != null)
                        ...((combatData['heroIds'] as List).map((id) {
                          final hId = id.toString();
                          final name = heroNameMap[hId] ?? hId;
                          final hp = latestHeroesHpMap![hId];
                          if (hp is int && hp == 0) {
                            return RichText(
                              text: TextSpan(
                                style: DefaultTextStyle.of(context).style,
                                children: [
                                  TextSpan(text: "$name "),
                                  const TextSpan(
                                      text: "(killed)",
                                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            );
                          } else {
                            return Text("$name (${hp ?? '?'} HP remaining)");
                          }
                        }).toList())
                      else
                      // PvE summary: single hero.
                        (latestHeroHp is int && latestHeroHp == 0)
                            ? RichText(
                          text: TextSpan(
                            style: DefaultTextStyle.of(context).style,
                            children: [
                              TextSpan(text: "${heroName ?? 'Hero'} "),
                              const TextSpan(
                                  text: "(killed)",
                                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                            : Text("${heroName ?? 'Hero'} (${latestHeroHp ?? '?'} HP remaining)"),
                      const SizedBox(height: 8),
                      // Show enemy summary only if this is a pure PvE fight or if it's a hybrid PvE/PvP (i.e. event exists).
                      if (showEnemySummary) ...[
                        Text("👹 Enemies:", style: const TextStyle(fontWeight: FontWeight.bold)),
                        if (latestEnemiesHp.isEmpty)
                          const Text("None remaining.")
                        else
                          ...List.generate(latestEnemiesHp.length, (i) {
                            final hp = latestEnemiesHp[i];
                            if (hp == 0) {
                              return RichText(
                                text: TextSpan(
                                  style: DefaultTextStyle.of(context).style,
                                  children: [
                                    TextSpan(text: "$enemyName #$i "),
                                    const TextSpan(
                                        text: "(killed)",
                                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              );
                            } else {
                              return Text("$enemyName #$i (${hp} HP remaining)");
                            }
                          }),
                      ],
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
                  final data = docs[index].data() as Map<String, dynamic>;
                  // Retrieve enemy attacks and timestamp.
                  final enemyAttacks = List<Map<String, dynamic>>.from(data['enemyAttacks'] ?? []);
                  final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
                  final timeString = timestamp != null
                      ? "${timestamp.hour.toString().padLeft(2, '0')}:"
                      "${timestamp.minute.toString().padLeft(2, '0')}:"
                      "${timestamp.second.toString().padLeft(2, '0')}"
                      : '';
                  // Build the hero attack widget.
                  Widget heroAttackWidget = const SizedBox.shrink();
                  // Case 1: PvP log with multiple hero attacks.
                  if (data.containsKey('heroAttacks') && data['heroAttacks'] is List) {
                    final List heroAttacks = data['heroAttacks'] as List;
                    List<Widget> attackWidgets = [];
                    for (final attack in heroAttacks) {
                      if (attack is Map) {
                        final rawAttackerId = attack['attackerId']?.toString() ?? '';
                        final attackerName = (heroNameMap != null && heroNameMap.containsKey(rawAttackerId))
                            ? heroNameMap[rawAttackerId]!
                            : rawAttackerId;
                        final targetType = attack['targetType']?.toString() ?? '';
                        final target = attack['target'];
                        final damage = attack['damage']?.toString() ?? '';
                        List<TextSpan> spans = [
                          const TextSpan(text: "🧙 "),
                          TextSpan(text: "$attackerName", style: const TextStyle(fontWeight: FontWeight.bold)),
                          const TextSpan(text: " hits "),
                        ];
                        if (targetType == 'enemy' && target is int) {
                          final enemyHp = (data['enemiesHpAfter'] is List &&
                              (data['enemiesHpAfter'] as List).isNotEmpty &&
                              target < (data['enemiesHpAfter'] as List).length)
                              ? (data['enemiesHpAfter'] as List)[target]
                              : '?';
                          spans.add(TextSpan(text: "$enemyName #$target", style: const TextStyle(fontWeight: FontWeight.bold)));
                          spans.add(TextSpan(text: " for $damage damage --> "));
                          spans.add(_buildOutcomeSpan(enemyHp, enemyName));
                        } else if (targetType == 'hero' && target is String) {
                          final targetName = (heroNameMap != null && heroNameMap.containsKey(target))
                              ? heroNameMap[target]!
                              : target;
                          final heroesHpAfter = data['heroesHpAfter'] is Map ? (data['heroesHpAfter'] as Map) : null;
                          final targetHp = (heroesHpAfter != null && heroesHpAfter.containsKey(target))
                              ? heroesHpAfter[target]
                              : '?';
                          spans.add(TextSpan(text: "$targetName", style: const TextStyle(fontWeight: FontWeight.bold)));
                          spans.add(TextSpan(text: " for $damage damage --> "));
                          spans.add(_buildOutcomeSpan(targetHp, targetName));
                        } else {
                          spans.add(TextSpan(text: "$target"));
                        }
                        attackWidgets.add(RichText(text: TextSpan(children: spans, style: DefaultTextStyle.of(context).style)));
                      }
                    }
                    heroAttackWidget = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: attackWidgets,
                    );
                  }
                  // Case 2: Fallback legacy PvE log processing.
                  else if (data.containsKey('heroAttack') && data['heroAttack'] != null) {
                    final dynamic heroAttackRaw = data['heroAttack'];
                    final targetEnemy = data['targetEnemyIndex'];
                    final pveHeroHpAfter = data['heroHpAfter'];
                    List<TextSpan> spans = [ const TextSpan(text: "🧙 ") ];
                    if (heroAttackRaw is Map) {
                      final rawAttackerId = heroAttackRaw['attackerId']?.toString() ?? '';
                      final attackerName = (heroNameMap != null && heroNameMap.containsKey(rawAttackerId))
                          ? heroNameMap[rawAttackerId]!
                          : rawAttackerId;
                      spans.add(TextSpan(text: "$attackerName", style: const TextStyle(fontWeight: FontWeight.bold)));
                      spans.add(const TextSpan(text: " hits "));
                      final targetType = heroAttackRaw['targetType']?.toString() ?? '';
                      final target = heroAttackRaw['target'];
                      final damage = heroAttackRaw['damage']?.toString() ?? '';
                      if (targetType == 'enemy' && target is int) {
                        final enemyHp = (data['enemiesHpAfter'] is List &&
                            (data['enemiesHpAfter'] as List).isNotEmpty &&
                            target < (data['enemiesHpAfter'] as List).length)
                            ? (data['enemiesHpAfter'] as List)[target]
                            : '?';
                        spans.add(TextSpan(text: "$enemyName #$target", style: const TextStyle(fontWeight: FontWeight.bold)));
                        spans.add(TextSpan(text: " for $damage damage --> "));
                        spans.add(_buildOutcomeSpan(enemyHp, enemyName));
                      } else if (targetType == 'hero') {
                        spans.add(TextSpan(text: "$target", style: const TextStyle(fontWeight: FontWeight.bold)));
                        spans.add(TextSpan(text: " for $damage damage"));
                      }
                      heroAttackWidget = RichText(text: TextSpan(children: spans, style: DefaultTextStyle.of(context).style));
                    } else if (heroAttackRaw is int && heroAttackRaw > 0 && targetEnemy != null) {
                      spans.add(TextSpan(text: heroName ?? 'Hero', style: const TextStyle(fontWeight: FontWeight.bold)));
                      spans.add(const TextSpan(text: " hits "));
                      spans.add(TextSpan(text: "$enemyName #$targetEnemy", style: const TextStyle(fontWeight: FontWeight.bold)));
                      spans.add(TextSpan(text: " for $heroAttackRaw damage --> "));
                      final enemyHp = (data['enemiesHpAfter'] is List &&
                          (data['enemiesHpAfter'] as List).isNotEmpty)
                          ? (data['enemiesHpAfter'] as List)[targetEnemy]
                          : '?';
                      spans.add(_buildOutcomeSpan(enemyHp, enemyName));
                      heroAttackWidget = RichText(text: TextSpan(children: spans, style: DefaultTextStyle.of(context).style));
                    }
                  }
                  // Build enemy attack widgets.
                  List<Widget> enemyAttackWidgets = [];
                  final heroHpAfterForEnemy = data['heroHpAfter'];
                  for (final attack in enemyAttacks) {
                    if (heroHpAfterForEnemy != null) {
                      final rawTargetHeroId = attack['heroId']?.toString() ?? '';
                      final targetHeroName = (heroNameMap != null && heroNameMap.containsKey(rawTargetHeroId))
                          ? heroNameMap[rawTargetHeroId]!
                          : rawTargetHeroId.isNotEmpty ? rawTargetHeroId : (heroName ?? 'Hero');
                      enemyAttackWidgets.add(
                        RichText(
                          text: TextSpan(
                            style: DefaultTextStyle.of(context).style,
                            children: [
                              const TextSpan(text: "👹 "),
                              TextSpan(text: "$enemyName #${attack['index']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                              const TextSpan(text: " strikes "),
                              TextSpan(text: targetHeroName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(text: " for ${attack['damage']} damage --> "),
                              _buildOutcomeSpan(heroHpAfterForEnemy, targetHeroName),
                            ],
                          ),
                        ),
                      );
                    }
                  }
                  final nothingHappened =
                  ((data.containsKey('heroAttack') &&
                      (data['heroAttack'] is int && data['heroAttack'] == 0)) ||
                      (!data.containsKey('heroAttack') &&
                          (!data.containsKey('heroAttacks') ||
                              (data['heroAttacks'] is List && (data['heroAttacks'] as List).isEmpty))) &&
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
                            // Display the attack logs.
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

  /// Wraps _buildCombatLogUIWithHeroMap:
  /// If more than one hero is in combat, fetch a mapping of hero IDs to hero names.
  Widget _buildCombatLogUI(BuildContext context, Map<String, dynamic> combatData, {String? description}) {
    final heroIds = combatData['heroIds'] is List
        ? (combatData['heroIds'] as List).map((e) => e.toString()).toList()
        : <String>[];
    if (heroIds.length > 1) {
      return FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('heroes')
            .where(FieldPath.documentId, whereIn: heroIds)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final heroNameMap = <String, String>{};
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            heroNameMap[doc.id] = data['heroName'] ?? 'Hero';
          }
          return _buildCombatLogUIWithHeroMap(context, combatData,
              description: description, heroNameMap: heroNameMap);
        },
      );
    } else {
      return _buildCombatLogUIWithHeroMap(context, combatData,
          description: description, heroNameMap: null);
    }
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
          final combatData = combatSnapshot.data!.data() as Map<String, dynamic>?;
          if (combatData == null) {
            return const Center(child: Text("Combat not found."));
          }
          final eventId = combatData['eventId'] as String?;
          if (eventId == null) {
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
                  final eventData = eventDoc.data() as Map<String, dynamic>?;
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
