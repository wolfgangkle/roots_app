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

        // Build a resilient name map that supports both `<id>` and `heroes/<id>`
        final List<dynamic> heroList = combatData['heroes'] ?? [];
        final Map<String, String> heroNameMap = {};
        for (final hero in heroList) {
          if (hero is Map) {
            final refPath = hero['refPath']?.toString();
            final name = (hero['name'] ?? 'Hero').toString();
            if (refPath != null) {
              final id = _lastSegment(refPath);
              heroNameMap[id] = name;        // key by id
              heroNameMap[refPath] = name;    // key by full path
            }
          }
        }

        final String? eventId = combatData['eventId'] as String?;
        if (eventId == null) {
          return _buildCombatLogUI(context, heroNameMap, null);
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
              final eventData =
              eventDoc.data() as Map<String, dynamic>?;
              description = eventData?['description'] as String?;
            }

            return _buildCombatLogUI(context, heroNameMap, description);
          },
        );
      },
    );
  }

  Widget _buildCombatLogUI(
      BuildContext context,
      Map<String, String> heroNameMap,
      String? description,
      ) {
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
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                  final data =
                  docs[index].data() as Map<String, dynamic>;

                  final time = (data['timestamp'] as Timestamp?)?.toDate();
                  final heroAttacks = List<Map<String, dynamic>>.from(
                      data['heroAttacks'] ?? []);
                  final enemyAttacks = List<Map<String, dynamic>>.from(
                      data['enemyAttacks'] ?? []);
                  final enemiesHp =
                  List<int>.from(data['enemiesHpAfter'] ?? []);

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

                  // 🧙 Hero Attacks (attackerId may be id, path, or DocumentReference)
                  for (final attack in heroAttacks) {
                    final rawAttacker = attack['attackerId'];
                    final attackerKey = _normalizeHeroKey(rawAttacker);
                    final attackerName =
                        heroNameMap[attackerKey] ??
                            heroNameMap['heroes/$attackerKey'] ?? // safety
                            attackerKey;

                    final targetIndex = attack['targetIndex'];
                    final damage = attack['damage'];
                    final hpLeft = (targetIndex is int &&
                        targetIndex < enemiesHp.length)
                        ? enemiesHp[targetIndex]
                        : '?';

                    lines.add(
                      "🧙 $attackerName hits 👹 Enemy #$targetIndex for $damage dmg → $hpLeft HP left",
                    );
                  }

                  // 👹 Enemy Attacks (heroId may be id, path, or DocumentReference)
                  for (final e in enemyAttacks) {
                    final rawHeroId = e['heroId'];
                    final heroKey = _normalizeHeroKey(rawHeroId);
                    final heroNm =
                        heroNameMap[heroKey] ??
                            heroNameMap['heroes/$heroKey'] ?? // safety
                            heroKey;

                    final enemyIndex = e['enemyIndex'];
                    final damage = e['damage'];
                    final hpLeft = heroesHp[heroKey] ??
                        heroesHp['heroes/$heroKey'] ??
                        '?';

                    lines.add(
                      "👹 Enemy #$enemyIndex hits 🧙 $heroNm for $damage dmg → $hpLeft HP left",
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
}
