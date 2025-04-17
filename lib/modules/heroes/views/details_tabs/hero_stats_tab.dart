import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'package:roots_app/modules/heroes/models/hero_model.dart';
import 'package:roots_app/modules/map/constants/tier1_map.dart';
import 'package:roots_app/modules/heroes/views/found_village_screen.dart';
import 'package:roots_app/modules/heroes/views/hero_movement_screen.dart';
import 'package:roots_app/modules/combat/views/combat_log_screen.dart';
import 'package:roots_app/screens/controllers/main_content_controller.dart';
import 'package:roots_app/screens/helpers/responsive_push.dart';

class HeroStatsTab extends StatefulWidget {
  final HeroModel hero;

  const HeroStatsTab({super.key, required this.hero});

  @override
  State<HeroStatsTab> createState() => _HeroStatsTabState();
}

class _HeroStatsTabState extends State<HeroStatsTab> {
  bool _checkingTile = false;
  Map<String, dynamic>? _slotLimits;
  Map<String, dynamic>? _slotUsage;
  int _currentMaxSlots = 0;
  int _usedSlots = 0;

  @override
  void initState() {
    super.initState();
    _loadSlotData();
  }

  Future<void> _loadSlotData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final profileSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('profile')
        .doc('main')
        .get();

    final data = profileSnap.data();
    if (data == null) return;

    setState(() {
      _slotLimits = data['slotLimits'] ?? {};
      _slotUsage = data['currentSlotUsage'] ?? {};
      _currentMaxSlots = data['currentMaxSlots'] ?? (_slotLimits?['maxSlots'] ?? 0);
      _usedSlots = (_slotUsage?['villages'] ?? 0) + (_slotUsage?['companions'] ?? 0);
    });
  }

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
    final isIdle = hero.state == 'idle';
    final isPlains = terrain == 'plains';

    if (!isIdle || !isPlains) return false;

    final usedVillages = _slotUsage?['villages'] ?? 0;
    final maxVillages = _slotLimits?['maxVillages'] ?? 0;

    if (hero.type == 'mage') {
      return _usedSlots < _currentMaxSlots;
    } else {
      return _usedSlots < _currentMaxSlots || usedVillages < maxVillages;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hero = widget.hero;
    final isMobile = MediaQuery.of(context).size.width < 1024;
    final bool isMoving = hero.state == 'moving' && hero.arrivesAt != null;
    final bool hasQueuedWaypoints = hero.movementQueue != null && hero.movementQueue!.isNotEmpty;
    final bool hasMovement = isMoving || hasQueuedWaypoints;

    return SingleChildScrollView(
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
            // ... your existing movement UI unchanged ...
          ],

          // ... your existing combat UI unchanged ...

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

          if (hero.type == 'companion') ...[
            const SizedBox(height: 8),
            Text(
              "💡 Companions can be converted into villages.\n"
                  "If no free slot is available, they will be sacrificed to make space.",
              style: const TextStyle(fontSize: 12, color: Colors.orange),
            ),
          ],
        ],
      ),
    );
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
