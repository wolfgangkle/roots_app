import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'package:roots_app/modules/village/data/items.dart';
import 'package:roots_app/modules/combat/data/enemy_data.dart';
import 'package:roots_app/modules/combat/data/event_data.dart';
import 'package:roots_app/modules/spells/data/spell_data.dart';
import 'package:roots_app/modules/village/data/building_definitions.dart';

Future<void> triggerPeacefulAIEvent(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);

  try {
    final result = await FirebaseFunctions.instance
        .httpsCallable('generatePeacefulEventFromAI')
        .call();

    final msg = result.data['message'] ?? 'Generated';
    messenger.showSnackBar(SnackBar(content: Text('🌿 $msg')));
  } catch (e) {
    if (kDebugMode) debugPrint('❌ Error generating peaceful event: $e');
    messenger.showSnackBar(
      const SnackBar(content: Text('❌ Failed to generate peaceful event')),
    );
  }
}

Future<void> triggerCombatAIEvent(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);

  try {
    final result = await FirebaseFunctions.instance
        .httpsCallable('generateCombatEventFromAI')
        .call();

    final msg = result.data['message'] ?? 'Generated';
    messenger.showSnackBar(SnackBar(content: Text('⚔️ $msg')));
  } catch (e) {
    if (kDebugMode) debugPrint('❌ Error generating combat event: $e');
    messenger.showSnackBar(
      const SnackBar(content: Text('❌ Failed to generate combat event')),
    );
  }
}

Future<void> seedSpells(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);

  final batch = FirebaseFirestore.instance.batch();
  final ref = FirebaseFirestore.instance.collection('spells');

  for (final spell in spellData) {
    final docRef = ref.doc(spell['id']);
    batch.set(docRef, {
      ...spell,
      'source': 'manual',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  await batch.commit();
  messenger.showSnackBar(
    const SnackBar(content: Text("✨ Seeded spells to Firestore!")),
  );
}

Future<void> seedCraftingItems(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);

  final batch = FirebaseFirestore.instance.batch();
  final itemsRef = FirebaseFirestore.instance.collection('items');

  for (final entry in gameItems.entries) {
    final itemId = entry.key;
    final data = entry.value;

    final docRef = itemsRef.doc(itemId);
    batch.set(docRef, {
      'itemId': itemId,
      ...data,
    }, SetOptions(merge: true));
  }

  await batch.commit();
  messenger.showSnackBar(
    const SnackBar(
        content: Text("⚒️ Seeded all crafting items into Firestore!")),
  );
}

Future<void> seedEnemies(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);

  final batch = FirebaseFirestore.instance.batch();
  final ref = FirebaseFirestore.instance.collection('enemyTypes');

  for (final enemy in enemyTypes) {
    final docRef = ref.doc(enemy['id']);
    batch.set(docRef, {
      ...enemy,
      'source': enemy['source'] ?? 'manual',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  await batch.commit();
  messenger.showSnackBar(
    const SnackBar(content: Text("💀 Seeded enemyTypes to Firestore!")),
  );
}

Future<void> seedEncounterEvents(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);

  final batch = FirebaseFirestore.instance.batch();
  final ref = FirebaseFirestore.instance.collection('encounterEvents');

  for (final event in encounterEvents) {
    final docRef = ref.doc(event['id']);
    batch.set(docRef, {
      ...event,
      'source': event['source'] ?? 'Wolfgang',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  await batch.commit();
  messenger.showSnackBar(
    const SnackBar(content: Text("🧪 Seeded encounterEvents to Firestore!")),
  );
}

Future<void> seedBuildingDefinitions(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);

  final batch = FirebaseFirestore.instance.batch();
  final ref = FirebaseFirestore.instance.collection('buildingDefinitions');

  for (final building in buildingDefinitions) {
    final buildingType = building['type'] as String?;
    if (buildingType == null) continue;

    final docRef = ref.doc(buildingType);
    batch.set(docRef, {
      ...building,
      'source': 'manual',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  await batch.commit();
  messenger.showSnackBar(
    const SnackBar(content: Text("🏗️ Seeded building definitions to Firestore!")),
  );
}


Future<void> cleanMapTiles(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);

  final tilesRef = FirebaseFirestore.instance.collection('mapTiles');
  final snapshot = await tilesRef.get();

  int cleaned = 0;
  for (final doc in snapshot.docs) {
    final data = doc.data();
    final cleanedData = {
      'terrain': data['terrain'],
      'x': data['x'],
      'y': data['y'],
    };

    final shouldClean =
    data.keys.any((k) => !['terrain', 'x', 'y'].contains(k));
    if (shouldClean) {
      await doc.reference.set(cleanedData, SetOptions(merge: false));
      cleaned++;
    }
  }

  messenger.showSnackBar(
    SnackBar(content: Text("🧹 Cleaned $cleaned mapTiles")),
  );
}
