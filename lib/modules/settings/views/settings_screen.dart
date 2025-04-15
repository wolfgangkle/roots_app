import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roots_app/modules/settings/models/user_settings_model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController exportController = TextEditingController();

  Future<void> _exportTier1MapToText() async {
    final mapRef = FirebaseFirestore.instance.collection('mapTiles');
    final snapshot = await mapRef.get();

    final buffer = StringBuffer();
    buffer.writeln('const Map<String, String> tier1Map = {');

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final id = doc.id;
      final terrain = data['terrain'] ?? 'plains';
      buffer.writeln("  '$id': '$terrain',");
    }

    buffer.writeln('};');

    setState(() {
      exportController.text = buffer.toString();
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Map exported into text field.")),
      );
    }
  }

  @override
  void dispose() {
    exportController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<UserSettingsModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Show Global Chat Overlay'),
            value: settings.showChatOverlay,
            onChanged: settings.setShowChatOverlay,
          ),

          const Divider(),

          // 🔒 Export to text field (temporarily disabled)
          /*
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.text_snippet),
            label: const Text("Export Tier 1 Map to Text"),
            onPressed: _exportTier1MapToText,
          ),
        ),

        if (exportController.text.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("📋 Copy-Paste Map Export:"),
              const SizedBox(height: 8),
              SizedBox(
                height: 400,
                child: TextField(
                  controller: exportController,
                  maxLines: null,
                  expands: true,
                  readOnly: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        */
        ],
      ),
    );
  }
}
