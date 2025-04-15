import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import 'package:roots_app/modules/heroes/models/hero_model.dart';
import 'package:roots_app/modules/heroes/views/hero_movement_screen.dart';
import 'package:roots_app/screens/controllers/main_content_controller.dart';
import 'package:roots_app/modules/combat/views/combat_log_screen.dart';
import 'package:roots_app/screens/helpers/responsive_push.dart';

import 'package:roots_app/modules/map/constants/tier1_map.dart'; // ← make sure this is imported
import 'package:roots_app/modules/heroes/views/found_village_screen.dart'; // ← create this screen next

class HeroDetailsScreen extends StatefulWidget {
  final HeroModel hero;

  const HeroDetailsScreen({required this.hero, super.key});

  @override
  State<HeroDetailsScreen> createState() => _HeroDetailsScreenState();
}

class _HeroDetailsScreenState extends State<HeroDetailsScreen> {
  bool _checkingTile = false;

  Future<void> _handleFoundVillage(HeroModel hero) async {
    setState(() => _checkingTile = true);

    final tileKey = '${hero.tileX}_${hero.tileY}';
    final snapshot = await FirebaseFirestore.instance
        .collectionGroup('villages')
        .where('tileKey', isEqualTo: tileKey)
        .limit(1)
        .get();

    final occupied = snapshot.docs.isNotEmpty;
    setState(() => _checkingTile = false);

    if (occupied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A village already exists on this tile!')),
      );
      return;
    }

    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => FoundVillageScreen(hero: hero),
    ));
  }

  bool _canFoundVillage(HeroModel hero) {
    final tileKey = '${hero.tileX}_${hero.tileY}';
    final terrain = tier1Map[tileKey];
    return hero.state == 'idle' && terrain == 'plains';
  }

  @override
  Widget build(BuildContext context) {
    final heroId = widget.hero.id;
    final isMobile = MediaQuery.of(context).size.width < 1024;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('heroes').doc(heroId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        if (data == null) {
          return const Scaffold(
            body: Center(child: Text("Hero not found.")),
          );
        }

        final hero = HeroModel.fromFirestore(heroId, data);
        final bool isMoving = hero.state == 'moving' && hero.arrivesAt != null;
        final bool hasQueuedWaypoints = hero.movementQueue != null && hero.movementQueue!.isNotEmpty;
        final bool hasMovement = isMoving || hasQueuedWaypoints;

        return Scaffold(
          appBar: AppBar(
            title: Text(hero.heroName),
            automaticallyImplyLeading: isMobile,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle("🧙 Hero Info"),
                Text("Name: ${hero.heroName}"),
                Text("Race: ${hero.race}"),
                Text("Level: ${hero.level}"),
                Text("Location: (${hero.tileX}, ${hero.tileY})"),
                Text("State: ${hero.state}"),

                if (hasMovement) ...[
                  const SizedBox(height: 12),
                  _sectionTitle("🧭 Movement Status"),
                  if (isMoving) ...[
                    _liveCountdown(hero.arrivesAt!),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text("Arrives at: ${_formatTimestamp(hero.arrivesAt!)}"),
                    ),
                    if (hero.destinationX != null && hero.destinationY != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text("Moving to: (${hero.destinationX}, ${hero.destinationY})"),
                      )
                    else if (hasQueuedWaypoints)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text("Moving to: (${hero.movementQueue!.first['x']}, ${hero.movementQueue!.first['y']})"),
                      ),
                  ],
                  if (hasQueuedWaypoints)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        const Text("Waypoints:"),
                        ...hero.movementQueue!.map((wp) => Text("• (${wp['x']}, ${wp['y']})", style: const TextStyle(fontSize: 12))),
                      ],
                    ),
                ],

                if (hero.state == 'in_combat') ...[
                  const SizedBox(height: 12),
                  _sectionTitle("⚔️ Combat Status"),
                  FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('combats')
                        .where('heroIds', arrayContains: hero.id)
                        .where('state', isEqualTo: 'ongoing')
                        .limit(1)
                        .get(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Text("Loading combat data...");
                      final docs = snapshot.data!.docs;
                      if (docs.isEmpty) return const Text("⚠️ Combat not found.");

                      final combat = docs.first.data() as Map<String, dynamic>;
                      final enemyType = combat['enemyType'] ?? '???';
                      final enemyCount = combat['enemyCount'] ?? '?';

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Engaged with $enemyCount $enemyType(s)"),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.remove_red_eye),
                            label: const Text('View Combat'),
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => CombatLogScreen(combatId: docs.first.id),
                              ));
                            },
                          ),
                        ],
                      );
                    },
                  )
                ],

                const SizedBox(height: 24),
                _sectionTitle("⚔️ Combat Stats"),
                _statRow("Experience", hero.experience.toString()),
                _statRow("Magic Resistance", hero.magicResistance.toString()),
                const SizedBox(height: 12),
                _barRow("HP", hero.hp, hero.hpMax, color: Colors.red),
                _barRow("Mana", hero.mana, hero.manaMax, color: Colors.blue),

                const SizedBox(height: 24),
                _sectionTitle("📊 Attributes"),
                _attributeBar("Strength", hero.stats['strength'] ?? 0),
                _attributeBar("Dexterity", hero.stats['dexterity'] ?? 0),
                _attributeBar("Intelligence", hero.stats['intelligence'] ?? 0),
                _attributeBar("Constitution", hero.stats['constitution'] ?? 0),

                const SizedBox(height: 24),
                _sectionTitle("🌿 Survival & Regen"),
                _statRow("HP Regen", "${hero.hpRegen}s"),
                _statRow("Mana Regen", "${hero.manaRegen}s"),
                _statRow("Food Duration", _formatDuration(hero.foodDuration)),

                const SizedBox(height: 32),
                ElevatedButton.icon(
                  icon: const Icon(Icons.edit_location_alt),
                  label: Text(hero.state == 'idle' ? 'Move Hero' : 'Edit Movement'),
                  onPressed: () {
                    if (isMobile) {
                      pushResponsiveScreen(context, HeroMovementScreen(hero: hero));
                    } else {
                      final controller = Provider.of<MainContentController>(context, listen: false);
                      controller.setCustomContent(HeroMovementScreen(hero: hero));
                    }
                  },
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.location_city),
                  label: const Text("Found New Village"),
                  onPressed: _checkingTile || !_canFoundVillage(hero)
                      ? null
                      : () => _handleFoundVillage(hero),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _liveCountdown(DateTime arrivesAt) {
    return StreamBuilder<DateTime>(
      stream: Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now()),
      builder: (context, snapshot) {
        final now = snapshot.data ?? DateTime.now();
        final remaining = arrivesAt.difference(now);
        final duration = remaining.isNegative ? Duration.zero : remaining;
        final mm = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
        final ss = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
        return Text("🕒 $mm:$ss until arrival", style: const TextStyle(fontSize: 12));
      },
    );
  }

  String _formatTimestamp(DateTime dt) {
    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} • ${dt.day}.${dt.month}.${dt.year}";
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
  );

  Widget _statRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(value),
      ],
    ),
  );

  Widget _barRow(String label, int current, int max, {required Color color}) {
    final percent = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: $current / $max"),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 8,
              backgroundColor: Colors.grey.shade300,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _attributeBar(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 140, child: Text(label)),
          Expanded(
            child: LinearProgressIndicator(
              value: value / 500,
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              color: Colors.brown,
            ),
          ),
          const SizedBox(width: 8),
          Text(value.toString()),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final parts = <String>[];
    if (hours > 0) parts.add('${hours}h');
    if (minutes > 0 || parts.isEmpty) parts.add('${minutes}m');
    return parts.join(' ');
  }
}
