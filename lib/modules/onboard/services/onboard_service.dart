import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Creates the user profile, hero, village and assigns a starting tile
  Future<void> createNewPlayer({
    required String heroName,
    required String villageName,
    required String startZone,
    required String race,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final uid = user.uid;

    // 🔻 MAP ZONE COORDINATE BOUNDS — UPDATE THESE FREELY LATER 🔻
    final Map<String, Map<String, int>> zoneBounds = {
      'north':  { 'minX': 0, 'maxX': 100, 'minY': 300, 'maxY': 400 },
      'south':  { 'minX': 0, 'maxX': 100, 'minY': 0,   'maxY': 100 },
      'east':   { 'minX': 300, 'maxX': 400, 'minY': 150, 'maxY': 250 },
      'west':   { 'minX': 0, 'maxX': 100, 'minY': 150, 'maxY': 250 },
    };
    // 🔺 MAP ZONE COORDINATE BOUNDS — FEEL FREE TO EXPAND 🔺

    final zone = zoneBounds[startZone];
    if (zone == null) throw Exception('Invalid zone selected: $startZone');

    final tile = await _findAvailableTile(zone, minDistance: 5);
    if (tile == null) throw Exception('Could not find a free tile in zone');

    final villageId = _db.collection('villages').doc().id;
    final heroId = _db.collection('heroes').doc().id;

    final batch = _db.batch();

    // 1. Create user profile
    final userProfileRef = _db.collection('users').doc(uid).collection('profile').doc('main');
    batch.set(userProfileRef, {
      'characterName': heroName,
      'race': race,
      'villageId': villageId,
      'mainHeroId': heroId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2. Create hero
    final heroRef = _db.collection('heroes').doc(heroId);
    batch.set(heroRef, {
      'ownerId': uid,
      'name': heroName,
      'isMainHero': true,
      'race': race,
      'level': 1,
      'hp': 100,
      'mana': 50,
      'tileX': tile['x'],
      'tileY': tile['y'],
    });

    // 3. Create village
    final villageRef = _db.collection('villages').doc(villageId);
    batch.set(villageRef, {
      'ownerId': uid,
      'name': villageName,
      'tileX': tile['x'],
      'tileY': tile['y'],
      'resources': {
        'wood': 100,
        'stone': 100,
        'food': 100,
        'iron': 50,
        'gold': 10,
      },
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 4. Optionally mark the tile as occupied
    final tileRef = _db.collection('tiles').doc('tile_${tile['x']}_${tile['y']}');
    batch.set(tileRef, {
      'occupiedBy': villageId,
    });

    await batch.commit();
  }

  /// Randomly finds an available tile in the zone with minDistance to others
  Future<Map<String, int>?> _findAvailableTile(
      Map<String, int> bounds, {int minDistance = 5}) async {
    final rand = Random();
    const maxTries = 50;

    for (int i = 0; i < maxTries; i++) {
      final x = rand.nextInt(bounds['maxX']! - bounds['minX']!) + bounds['minX']!;
      final y = rand.nextInt(bounds['maxY']! - bounds['minY']!) + bounds['minY']!;

      // 🧱 NEW CHECK: Exclude invalid terrain tiles (future-ready!)
      final tileDoc = await _db.collection('tiles').doc('tile_${x}_$y').get();
      if (tileDoc.exists && ['water', 'mountain', 'ice', 'forest'].contains(tileDoc['terrain'])) {
        continue; // Skip bad terrain tiles
      }

      // 🧍‍♂️ Check for proximity to other villages
      final nearby = await _db
          .collection('villages')
          .where('tileX', isGreaterThanOrEqualTo: x - minDistance)
          .where('tileX', isLessThanOrEqualTo: x + minDistance)
          .get();

      final isTooClose = nearby.docs.any((doc) {
        final dx = (doc['tileX'] - x).abs();
        final dy = (doc['tileY'] - y).abs();
        return dx <= minDistance && dy <= minDistance;
      });

      if (!isTooClose) {
        return { 'x': x, 'y': y };
      }
    }

    return null; // fallback if we fail to find a valid tile
  }
}
