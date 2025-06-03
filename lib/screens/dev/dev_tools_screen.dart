import 'package:flutter/material.dart';
import 'package:roots_app/screens/dev/tools/map_tools.dart';
import 'package:roots_app/screens/dev/tools/seeding_tools.dart';
import 'package:roots_app/screens/dev/tools/ai_tools.dart';
import 'package:roots_app/screens/dev/tools/misc_tools.dart';

class DevToolsScreen extends StatelessWidget {
  const DevToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🛠️ Developer Tools'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader('🌍 Map Tools'),
          const MapToolsSection(),

          const SizedBox(height: 24),
          _sectionHeader('🧬 Seeder Tools'),
          const SeedingToolsSection(),

          const SizedBox(height: 24),
          _sectionHeader('🤖 AI Tools'),
          const AIToolsSection(),

          const SizedBox(height: 24),
          _sectionHeader('⚙️ Misc Tools'),
          const MiscToolsSection(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }
}
