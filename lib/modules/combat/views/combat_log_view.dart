// lib/modules/combat/combat_log_view.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import 'package:roots_app/theme/app_style_manager.dart';
import 'package:roots_app/theme/widgets/token_panels.dart';

class CombatLogView extends StatefulWidget {
  final String combatId;

  const CombatLogView({super.key, required this.combatId});

  @override
  State<CombatLogView> createState() => _CombatLogViewState();
}

class _CombatLogViewState extends State<CombatLogView> {
  @override
  Widget build(BuildContext context) {
    final combatDocRef =
    FirebaseFirestore.instance.collection('combats').doc(widget.combatId);

    return FutureBuilder<DocumentSnapshot>(
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

        // ---------- Build hero name map (supports id, heroes/<id>, refPath) ----------
        final List<dynamic> heroList = combatData['heroes'] ?? [];
        final Map<String, String> heroNameMap = {};
        for (final hero in heroList) {
          if (hero is Map) {
            final name = (hero['name'] ?? 'Hero').toString();

            // Prefer explicit id if present
            final idField = hero['id']?.toString();
            if (idField != null && idField.isNotEmpty) {
              heroNameMap[idField] = name;
              heroNameMap['heroes/$idField'] = name; // safety for path-style keys
            }

            // Also support refPath if present
            final refPath = hero['refPath']?.toString();
            if (refPath != null && refPath.isNotEmpty) {
              final idFromPath = _lastSegment(refPath);
              heroNameMap[idFromPath] = name;
              heroNameMap[refPath] = name;
            }
          }
        }

        // ---------- Build enemy name map keyed by instanceId (stable labels) ----------
        final List<dynamic> enemies = combatData['enemies'] ?? [];
        final Map<String, String> enemyNameMap = {};
        for (var i = 0; i < enemies.length; i++) {
          final e = enemies[i] as Map<String, dynamic>? ?? {};
          final instanceId = (e['instanceId'] ?? e['id'] ?? '').toString();
          if (instanceId.isEmpty) continue;

          final baseName =
          (e['name'] ?? e['enemyType'] ?? e['type'] ?? 'Enemy').toString();
          final pretty = _titleCase(baseName);
          final displayNum =
          (e['spawnIndex'] is int) ? (e['spawnIndex'] as int) + 1 : (i + 1);

          enemyNameMap[instanceId] = "$pretty #$displayNum";
        }

        // If backend provided a baked map, prefer/merge it
        final baked = combatData['enemyNameMap'];
        if (baked is Map) {
          baked.forEach((k, v) {
            if (k is String && v is String) {
              enemyNameMap[k] = v;
            }
          });
        }

        final String? eventId = combatData['eventId'] as String?;
        if (eventId == null) {
          return _buildCombatLogUI(
            context: context,
            heroNameMap: heroNameMap,
            enemyNameMap: enemyNameMap,
            enemies: enemies,
            description: null,
          );
        }

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('encounterEvents')
              .doc(eventId)
              .get(),
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

            return _buildCombatLogUI(
              context: context,
              heroNameMap: heroNameMap,
              enemyNameMap: enemyNameMap,
              enemies: enemies,
              description: description,
            );
          },
        );
      },
    );
  }

  Widget _buildCombatLogUI({
    required BuildContext context,
    required Map<String, String> heroNameMap,
    required Map<String, String> enemyNameMap,
    required List<dynamic> enemies,
    required String? description,
  }) {
    final style = context.watch<StyleManager>().currentStyle;
    final text = style.textOnGlass;

    final combatLogRef = FirebaseFirestore.instance
        .collection('combats')
        .doc(widget.combatId)
        .collection('combatLog')
        .orderBy('tick');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header (transparent)
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Text(
            "⚔️ Combat Log",
            style: TextStyle(
              color: text.primary,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),

        // Optional description in a small token panel
        if (description != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TokenPanel(
              glass: style.glass,
              text: text,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              borderRadius: style.radius.card.toDouble(),
              child: Text(
                description,
                style: TextStyle(
                  color: text.secondary,
                  fontStyle: FontStyle.italic,
                  height: 1.25,
                ),
              ),
            ),
          ),

        // Log list
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: StreamBuilder<QuerySnapshot>(
            stream: combatLogRef.snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final docs = snapshot.data!.docs.reversed.toList(); // latest first

              if (docs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    "No combat log entries.",
                    style: TextStyle(color: text.subtle),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;

                  final time = (data['timestamp'] as Timestamp?)?.toDate();
                  final heroAttacks =
                  List<Map<String, dynamic>>.from(data['heroAttacks'] ?? []);
                  final enemyAttacks =
                  List<Map<String, dynamic>>.from(data['enemyAttacks'] ?? []);

                  // Legacy array (order-based)
                  final enemiesHpAfter =
                  List<int>.from(data['enemiesHpAfter'] ?? []);

                  // New stable map, keyed by instanceId
                  final Map<String, dynamic> enemiesHpAfterMapRaw =
                  Map<String, dynamic>.from(data['enemiesHpAfterMap'] ?? {});
                  final Map<String, int> enemiesHpAfterMap = {
                    for (final e in enemiesHpAfterMapRaw.entries)
                      e.key.toString(): (e.value is int
                          ? e.value as int
                          : int.tryParse(e.value.toString()) ?? 0),
                  };

                  // normalize heroesHp keys (id vs path vs ref)
                  final heroesHpRaw =
                  Map<String, dynamic>.from(data['heroesHpAfter'] ?? {});
                  final heroesHp = <String, dynamic>{
                    for (final entry in heroesHpRaw.entries)
                      _normalizeHeroKey(entry.key): entry.value
                  };

                  // Skip empty ticks
                  if (heroAttacks.isEmpty && enemyAttacks.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  // Build a compact summary block as a token bubble
                  final lines = <String>[];
                  if (time != null) {
                    final hh = time.hour.toString().padLeft(2, '0');
                    final mm = time.minute.toString().padLeft(2, '0');
                    final ss = time.second.toString().padLeft(2, '0');
                    lines.add('[$hh:$mm:$ss]');
                  }

                  // 🧙 Hero Attacks (prefer targetEnemyId if present; else fall back to targetIndex)
                  for (final attack in heroAttacks) {
                    final rawAttacker = attack['attackerId'];
                    final attackerKey = _normalizeHeroKey(rawAttacker);
                    final attackerName = heroNameMap[attackerKey] ??
                        heroNameMap['heroes/$attackerKey'] ?? // safety
                        attackerKey;

                    final targetEnemyId = attack['targetEnemyId'];
                    final targetIndex = attack['targetIndex'];
                    final damage = attack['damage'];

                    String enemyLabel = 'Enemy';
                    String hpLeftStr = '?';

                    if (targetEnemyId is String &&
                        targetEnemyId.isNotEmpty &&
                        enemyNameMap.containsKey(targetEnemyId)) {
                      enemyLabel = enemyNameMap[targetEnemyId]!;
                      final hpLeft = enemiesHpAfterMap[targetEnemyId];
                      if (hpLeft != null) hpLeftStr = hpLeft.toString();
                    } else if (targetIndex is int) {
                      // Back-compat: resolve via index to an instanceId if possible
                      final label = _enemyLabelFromIndex(
                          targetIndex, enemies, enemyNameMap);
                      enemyLabel = label;

                      final hpLeft = (targetIndex >= 0 &&
                          targetIndex < enemiesHpAfter.length)
                          ? enemiesHpAfter[targetIndex]
                          : null;
                      if (hpLeft != null) hpLeftStr = hpLeft.toString();
                    }

                    lines.add(
                      "🧙 $attackerName hits 👹 $enemyLabel for $damage dmg → $hpLeftStr HP left",
                    );
                  }

                  // 👹 Enemy Attacks (prefer attackerId; fall back to enemyIndex for legacy)
                  for (final e in enemyAttacks) {
                    final rawHeroId = e['heroId'];
                    final heroKey = _normalizeHeroKey(rawHeroId);
                    final heroNm = heroNameMap[heroKey] ??
                        heroNameMap['heroes/$heroKey'] ?? // safety
                        heroKey;

                    final attackerId = e['attackerId'];
                    final enemyIndex = e['enemyIndex'];
                    final damage = e['damage'];

                    String enemyLabel = 'Enemy';

                    if (attackerId is String &&
                        attackerId.isNotEmpty &&
                        enemyNameMap.containsKey(attackerId)) {
                      enemyLabel = enemyNameMap[attackerId]!;
                    } else if (enemyIndex is int) {
                      // Legacy fallback
                      enemyLabel = _enemyLabelFromIndex(
                          enemyIndex, enemies, enemyNameMap);
                    }

                    final hpLeft =
                        heroesHp[heroKey] ?? heroesHp['heroes/$heroKey'] ?? '?';

                    lines.add(
                      "👹 $enemyLabel hits 🧙 $heroNm for $damage dmg → $hpLeft HP left",
                    );
                  }

                  return Padding(
                    padding:
                    const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                    child: TokenPanel(
                      glass: style.glass,
                      text: text,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      borderRadius: 12,
                      child: Text(
                        lines.join('\n'),
                        style: TextStyle(
                          color: text.primary,
                          fontSize: 13,
                          height: 1.25,
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

  // ---------- helpers ----------

  // Accepts String (id or path) or DocumentReference
  String _normalizeHeroKey(dynamic v) {
    if (v == null) return '?';
    if (v is DocumentReference) return v.id;
    final s = v.toString();
    return _lastSegment(s);
  }

  String _lastSegment(String s) {
    final i = s.lastIndexOf('/');
    return i >= 0 ? s.substring(i + 1) : s;
  }

  static String _titleCase(String s) {
    if (s.isEmpty) return s;
    final parts = s.replaceAll(RegExp(r'[_\-]+'), ' ').split(' ');
    return parts
        .where((p) => p.isNotEmpty)
        .map((p) => p[0].toUpperCase() + p.substring(1).toLowerCase())
        .join(' ');
  }

  /// Resolve a stable enemy label from a tick-local index using the combat.enemies list
  /// and the stable enemyNameMap keyed by instanceId.
  String _enemyLabelFromIndex(
      int idx,
      List<dynamic> enemies,
      Map<String, String> enemyNameMap,
      ) {
    if (idx < 0 || idx >= enemies.length) return 'Enemy #$idx';

    final e = enemies[idx] as Map<String, dynamic>? ?? {};
    final instanceId = (e['instanceId'] ?? e['id'] ?? '').toString();

    if (instanceId.isNotEmpty && enemyNameMap.containsKey(instanceId)) {
      return enemyNameMap[instanceId]!;
    }

    // Fallback label if map is missing
    final baseName =
    (e['name'] ?? e['enemyType'] ?? e['type'] ?? 'Enemy').toString();
    final pretty = _titleCase(baseName);
    final displayNum =
    (e['spawnIndex'] is int) ? (e['spawnIndex'] as int) + 1 : (idx + 1);
    return "$pretty #$displayNum";
  }
}
