// This is the new modular CombatLogView widget version of CombatLogScreen.
// It takes the same combatId but doesn't use a Scaffold,
// so it can be embedded in other screens like ReportDetailScreen.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

        final eventId = combatData['eventId'] as String?;

        if (eventId == null) {
          return Text("💥 Combat view rendering is TODO (requires extraction of full log view)");
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
                return Text('Error: \${eventSnapshot.error}');
              }
              final eventDoc = eventSnapshot.data;
              String? description;
              if (eventDoc != null && eventDoc.exists) {
                final eventData = eventDoc.data() as Map<String, dynamic>?;
                description = eventData?['description'] as String?;
              }
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("📋 Combat view content would go here\n(description: \$description)\nTODO: port logic from CombatLogScreen"),
              );
            },
          );
        }
      },
    );
  }
}
