import 'package:flutter/material.dart';
import 'package:roots_app/modules/heroes/models/hero_model.dart';

class HeroCard extends StatelessWidget {
  final HeroModel hero;
  final VoidCallback? onTap;

  const HeroCard({required this.hero, this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    final percentHp = hero.hpMax > 0 ? (hero.hp / hero.hpMax).clamp(0.0, 1.0) : 0.0;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(hero.heroName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Level ${hero.level} • ${hero.race}"),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: percentHp,
              backgroundColor: Colors.grey.shade300,
              color: Colors.red.shade400,
              minHeight: 6,
            ),
            const SizedBox(height: 2),
            Text("HP: ${hero.hp} / ${hero.hpMax}", style: const TextStyle(fontSize: 12)),
          ],
        ),

      ),
    );
  }
}
