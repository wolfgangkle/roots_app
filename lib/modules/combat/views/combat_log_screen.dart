// lib/modules/combat/combat_log_screen.dart (CombatLogView)
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
    final heroId = (data?['heroIds'] is List && (data?['heroIds'] as List).isNotEmpty)
        ? (data?['heroIds'] as List).first
        : null;

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

  @override
  Widget build(BuildContext context) {
    final style = context.watch<StyleManager>().currentStyle;
    final text = style.textOnGlass;

    final combatRef =
    FirebaseFirestore.instance.collection('combats').doc(widget.combatId);

    return FutureBuilder<DocumentSnapshot>(
      future: combatRef.get(),
      builder: (context, combatSnapshot) {
        if (combatSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!combatSnapshot.hasData || !combatSnapshot.data!.exists) {
          return const Center(child: Text("Combat not found."));
        }

        final combatData =
            combatSnapshot.data!.data() as Map<String, dynamic>? ?? {};
        final eventId = combatData['eventId'] as String?;
        final eventTitle = combatData['eventTitle'] as String?;
        final combatState = (combatData['state'] ?? '').toString(); // e.g., active/ended
        final tick = combatData['tick'];
        // removed: createdAt (unused)

        // Header (transparent, no panel)
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: Text(
                '📜 Combat Log',
                style: TextStyle(
                  color: text.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),

            // Optional line under header with small meta (transparent)
            if (combatState.isNotEmpty || tick != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Text(
                  [
                    if (eventTitle != null) 'Event: $eventTitle',
                    if (combatState.isNotEmpty) 'State: $combatState',
                    if (tick != null) 'Tick: $tick',
                  ].join('  •  '),
                  style: TextStyle(
                    color: text.subtle.withOpacity(0.95),
                    fontSize: 12,
                  ),
                ),
              ),

            // If there is an event, show a small token card with description so it doesn’t get lost
            if (eventId != null)
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('encounterEvents')
                    .doc(eventId)
                    .get(),
                builder: (context, eventSnap) {
                  if (eventSnap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final eventData =
                  eventSnap.data?.data() as Map<String, dynamic>?;

                  final description = eventData?['description']?.toString();
                  final prettyTitle = eventData?['title']?.toString();

                  if (description == null && prettyTitle == null) {
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: TokenPanel(
                      glass: style.glass,
                      text: text,
                      padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      borderRadius: style.radius.card.toDouble(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (prettyTitle != null)
                            Text(
                              prettyTitle,
                              style: TextStyle(
                                color: text.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          if (description != null) ...[
                            if (prettyTitle != null) const SizedBox(height: 4),
                            Text(
                              description,
                              style: TextStyle(
                                color: text.secondary,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),

            // The log list itself: transparent area with token "bubbles" per entry
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: StreamBuilder<QuerySnapshot>(
                  stream: combatRef
                      .collection('combatLog')
                      .orderBy('tick')
                      .snapshots(),
                  builder: (context, logSnap) {
                    if (logSnap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (logSnap.hasError) {
                      return Center(child: Text('Error: ${logSnap.error}'));
                    }

                    final docs = logSnap.data?.docs ?? const [];
                    if (docs.isEmpty) {
                      return Center(
                        child: Text(
                          'No log entries yet.',
                          style: TextStyle(color: text.subtle),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final d = docs[index];
                        final m = d.data() as Map<String, dynamic>? ??
                            <String, dynamic>{};

                        final entryTick = m['tick'];
                        // removed: phase, when (unused)
                        final summary =
                            m['text'] ?? m['summary'] ?? _guessSummaryFromEntry(m);

                        // one compact token bubble per log line
                        return Padding(
                          padding:
                          const EdgeInsets.symmetric(vertical: 3, horizontal: 0),
                          child: TokenPanel(
                            glass: style.glass,
                            text: text,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            borderRadius: 12,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (entryTick != null)
                                  Text(
                                    '[$entryTick] ',
                                    style: TextStyle(
                                      color: text.subtle.withOpacity(0.95),
                                      fontSize: 12,
                                    ),
                                  ),
                                Expanded(
                                  child: Text(
                                    summary.toString(),
                                    style: TextStyle(
                                      color: text.primary,
                                      fontSize: 13,
                                      height: 1.25,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Best-effort summary if there is no friendly 'text' or 'summary' field
  String _guessSummaryFromEntry(Map<String, dynamic> m) {
    // Try to condense hero/enemy attack arrays into a short line
    final heroAttacks = (m['heroAttacks'] as List?)?.length ?? 0;
    final enemyAttacks = (m['enemyAttacks'] as List?)?.length ?? 0;

    if (heroAttacks > 0 || enemyAttacks > 0) {
      return [
        if (heroAttacks > 0) 'Hero attacks: $heroAttacks',
        if (enemyAttacks > 0) 'Enemy attacks: $enemyAttacks',
      ].join(' • ');
    }

    // Fallback: compact JSON
    return m.toString();
  }
}
