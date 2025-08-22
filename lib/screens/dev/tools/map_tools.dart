import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MapToolsSection extends StatefulWidget {
  const MapToolsSection({super.key});

  @override
  State<MapToolsSection> createState() => _MapToolsSectionState();
}

class _MapToolsSectionState extends State<MapToolsSection> {
  final TextEditingController exportController = TextEditingController();

  @override
  void dispose() {
    exportController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasExport = exportController.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.upload_file),
          label: const Text("🗺️ Generate + Upload Tier 2 Map"),
          onPressed: () => _generateTier2Map(context),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          icon: const Icon(Icons.cleaning_services),
          label: const Text("🧼 Clean mapTiles (terrain/x/y only)"),
          onPressed: () => _cleanMapTiles(context),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          icon: const Icon(Icons.download),
          label: const Text("📄 Export Tier 2 Map to Dart Code"),
          onPressed: _exportTier2MapToDart,
        ),
        const SizedBox(height: 12),
        if (hasExport)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("📋 Copy-paste result:"),
              const SizedBox(height: 8),
              SizedBox(
                height: 300,
                child: TextField(
                  controller: exportController,
                  readOnly: true,
                  expands: true,
                  maxLines: null,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    isDense: true,
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.05),
                  ),
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Future<void> _exportTier2MapToDart() async {
    final messenger = ScaffoldMessenger.of(context); // capture before awaits

    final snapshot = await FirebaseFirestore.instance.collection('mapTiles').get();
    final buffer = StringBuffer()
      ..writeln("const Map<String, String> tier2Map = {");

    for (var doc in snapshot.docs) {
      final id = doc.id;
      final terrain = doc['terrain'] ?? 'plains';
      buffer.writeln("  '$id': '$terrain',");
    }

    buffer.writeln("};");

    if (!mounted) return; // guard before setState/SnackBar

    setState(() {
      exportController.text = buffer.toString();
    });

    messenger.showSnackBar(
      const SnackBar(content: Text("✅ Tier 2 map exported to Dart format")),
    );
  }

  Future<void> _generateTier2Map(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context); // capture before awaits
    final mapRef = FirebaseFirestore.instance.collection('mapTiles');

    const radius = 50;
    const innerRadius = 45.0;
    final rand = Random();
    final allTiles = <String, Map<String, dynamic>>{};

    // Step 1: Fill all valid land with plains or water
    for (int x = -radius; x <= radius; x++) {
      for (int y = -radius; y <= radius; y++) {
        final dist = sqrt(x * x + y * y);
        final id = '${x}_$y';

        String terrain;
        if (x.abs() == radius || y.abs() == radius || dist > innerRadius) {
          terrain = 'water';
        } else {
          terrain = 'plains';
        }

        allTiles[id] = {'x': x, 'y': y, 'terrain': terrain};
      }
    }

    // Step 2: Apply biome clusters over plains
    void addBiomeCluster(String terrain, int count, int minSize, int maxSize) {
      for (int i = 0; i < count; i++) {
        final centerX = rand.nextInt(radius * 2) - radius;
        final centerY = rand.nextInt(radius * 2) - radius;
        final brushSize = minSize + rand.nextInt(maxSize - minSize + 1);

        for (int dx = -brushSize; dx <= brushSize; dx++) {
          for (int dy = -brushSize; dy <= brushSize; dy++) {
            final tx = centerX + dx;
            final ty = centerY + dy;
            final tid = '${tx}_$ty';
            final tile = allTiles[tid];
            if (tile != null && tile['terrain'] == 'plains') {
              allTiles[tid] = {'x': tx, 'y': ty, 'terrain': terrain};
            }
          }
        }
      }
    }

    addBiomeCluster('forest', 8, 2, 4);
    addBiomeCluster('swamp', 4, 2, 3);
    addBiomeCluster('tundra', 4, 2, 3);
    addBiomeCluster('snow', 4, 2, 3);
    // Optional: sprinkle water clusters too for lakes
    addBiomeCluster('water', 3, 1, 2);

    // Step 3: Upload
    final batch = FirebaseFirestore.instance.batch();
    for (final entry in allTiles.entries) {
      final id = entry.key;
      final tile = entry.value;
      batch.set(mapRef.doc(id), tile);
    }

    await batch.commit();

    if (!mounted) return;

    messenger.showSnackBar(
      const SnackBar(content: Text("🏝️ Biome island generated!")),
    );
  }

  Future<void> _cleanMapTiles(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context); // capture before awaits

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

      final shouldClean = data.keys.any((k) => !['terrain', 'x', 'y'].contains(k));
      if (shouldClean) {
        await doc.reference.set(cleanedData, SetOptions(merge: false));
        cleaned++;
      }
    }

    if (!mounted) return;

    messenger.showSnackBar(
      SnackBar(content: Text("🧹 Cleaned $cleaned mapTiles")),
    );
  }
}
