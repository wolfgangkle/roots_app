import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roots_app/modules/heroes/models/hero_model.dart';
import 'package:roots_app/modules/heroes/views/hero_movement_screen.dart';
import 'package:provider/provider.dart';
import 'package:roots_app/screens/controllers/main_content_controller.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'dart:async';
import 'package:roots_app/modules/combat/views/combat_log_screen.dart';
import 'package:roots_app/screens/helpers/responsive_push.dart';






class HeroDetailsScreen extends StatefulWidget {
  final HeroModel hero;

  const HeroDetailsScreen({required this.hero, super.key});

  @override
  State<HeroDetailsScreen> createState() => _HeroDetailsScreenState();
}

class _HeroDetailsScreenState extends State<HeroDetailsScreen> {
  @override
  void initState() {
    super.initState();
    _checkAndRecoverStuckHero();
  }

  void _checkAndRecoverStuckHero() async {
    final hero = widget.hero;
    final arrivesAt = hero.arrivesAt;
    final now = DateTime.now();

    if (hero.state == 'moving' && arrivesAt != null && now.isAfter(arrivesAt)) {
      print('⚠️ Lazy fallback triggered for stuck hero: ${hero.heroName} (${hero.id})');
      try {
        final callable = FirebaseFunctions.instance.httpsCallable('processHeroArrivalCallable');
        await callable.call({'heroId': hero.id});
        print('✅ Fallback call sent for ${hero.id}');
      } catch (e) {
        print('🔥 Fallback failed: $e');
      }
    } else {
      print('🧼 Hero ${hero.heroName} does not need fallback');
    }
  }

  @override
  Widget build(BuildContext context) {
    final hero = widget.hero;
    final isMobile = MediaQuery.of(context).size.width < 1024;

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

            if (hero.state == 'moving' && hero.arrivesAt != null) ...[
              const SizedBox(height: 12),
              _sectionTitle("🧭 Movement Status"),
              _liveCountdown(hero.arrivesAt!),
              const SizedBox(height: 4),
              Text("Arrives at: ${_formatTimestamp(hero.arrivesAt!)}"),
              if (hero.destinationX != null && hero.destinationY != null)
                Text("Moving to: (${hero.destinationX}, ${hero.destinationY})"),
              if (hero.movementQueue != null && hero.movementQueue!.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    const Text("Waypoints:"),
                    ...hero.movementQueue!.map((wp) {
                      return Text("• (${wp['x']}, ${wp['y']})", style: const TextStyle(fontSize: 12));
                    }),
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
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CombatLogScreen(combatId: docs.first.id),
                            ),
                          );
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

            if (hero.state == 'idle') ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.directions_walk),
                label: const Text('Move Hero'),
                onPressed: () {
                  if (isMobile) {
                    pushResponsiveScreen(context, HeroMovementScreen(hero: hero));
                  } else {
                    final controller = Provider.of<MainContentController>(context, listen: false);
                    controller.setCustomContent(HeroMovementScreen(hero: hero));
                  }
                },
              ),
            ] else ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.hourglass_top),
                label: const Text('Hero is busy'),
                onPressed: null,
              ),
            ]
          ],
        ),
      ),
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
