import 'package:flutter/material.dart';
import 'package:roots_app/screens/dev/seed_functions.dart';

class SeedingToolsSection extends StatelessWidget {
  const SeedingToolsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.bolt),
          label: const Text("⚒️ Seed Crafting Items"),
          onPressed: () => seedCraftingItems(context),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          icon: const Icon(Icons.shield),
          label: const Text("💀 Seed Enemies"),
          onPressed: () => seedEnemies(context),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          icon: const Icon(Icons.local_fire_department),
          label: const Text("🧪 Seed Encounter Events"),
          onPressed: () => seedEncounterEvents(context),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          icon: const Icon(Icons.auto_fix_high),
          label: const Text("✨ Seed Spells"),
          onPressed: () => seedSpells(context),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          icon: const Icon(Icons.apartment),
          label: const Text("🏗️ Seed Buildings"),
          onPressed: () => seedBuildingDefinitions(context),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          icon: const Icon(Icons.currency_exchange),
          label: const Text("💱 Seed Trading Rates"),
          onPressed: () => seedTradingRates(context),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          icon: const Icon(Icons.map),
          label: const Text("🌍 Seed Terrain Types"),
          onPressed: () => seedTerrainTypes(context),
        ),
      ],
    );
  }
}
