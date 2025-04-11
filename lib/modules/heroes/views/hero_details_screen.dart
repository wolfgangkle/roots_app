import 'package:flutter/material.dart';
import 'package:roots_app/modules/heroes/models/hero_model.dart';
import 'package:roots_app/modules/heroes/views/hero_movement_screen.dart';
import 'package:provider/provider.dart';
import 'package:roots_app/screens/controllers/main_content_controller.dart';


class HeroDetailsScreen extends StatelessWidget {
  final HeroModel hero;

  const HeroDetailsScreen({required this.hero, super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 1024;

    return Scaffold(
      appBar: AppBar(
        title: Text(hero.heroName),
        automaticallyImplyLeading: isMobile, // ✅ only show back arrow on mobile
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
                  final controller = Provider.of<MainContentController>(context, listen: false);
                  controller.setCustomContent(HeroMovementScreen(hero: hero));
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
