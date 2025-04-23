import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:roots_app/modules/heroes/models/hero_model.dart';

class HeroResourcesTab extends StatefulWidget {
  final HeroModel hero;

  const HeroResourcesTab({super.key, required this.hero});

  @override
  State<HeroResourcesTab> createState() => _HeroResourcesTabState();
}

class _HeroResourcesTabState extends State<HeroResourcesTab> {
  Map<String, int> sourceResources = {
    "wood": 0,
    "stone": 0,
    "iron": 0,
    "food": 0,
    "gold": 0,
  };

  String? villageId;
  String? tileKey;
  bool insideVillage = false;
  bool _loading = true;
  bool _busy = false;

  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (var res in sourceResources.keys) {
      _controllers[res] = TextEditingController(text: "0");
    }
    _loadResourceSource();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadResourceSource() async {
    setState(() {
      _loading = true;
    });

    final groupId = widget.hero.groupId;
    if (groupId == null) return;

    final groupSnap = await FirebaseFirestore.instance.collection('heroGroups').doc(groupId).get();
    final groupData = groupSnap.data();
    if (groupData == null) return;

    tileKey = groupData['tileKey'] as String?;
    insideVillage = groupData['insideVillage'] as bool? ?? false;

    if (tileKey == null) return;

    final tileSnap = await FirebaseFirestore.instance.collection('mapTiles').doc(tileKey).get();
    final tileData = tileSnap.data();

    if (insideVillage && tileData?['villageId'] != null) {
      final id = tileData!['villageId'];
      villageId = id;

      final villageSnap = await FirebaseFirestore.instance
          .doc('users/${widget.hero.ownerId}/villages/$id')
          .get();

      final raw = villageSnap.data()?['resources'] as Map<String, dynamic>? ?? {};
      setState(() {
        sourceResources = {
          for (final key in sourceResources.keys) key: (raw[key] ?? 0) as int,
        };
        _loading = false;
      });
    } else {
      final raw = tileData?['resources'] as Map<String, dynamic>? ?? {};
      setState(() {
        villageId = null;
        sourceResources = {
          for (final key in sourceResources.keys) key: (raw[key] ?? 0) as int,
        };
        _loading = false;
      });
    }
  }

  Future<void> _transferAll({required bool pickUp}) async {
    if (tileKey == null) return;

    final changes = <String, int>{};

    for (final key in sourceResources.keys) {
      final amount = pickUp ? sourceResources[key]! : (widget.hero.carriedResources[key] ?? 0);
      if (amount > 0) {
        changes[key] = pickUp ? amount : -amount;
      }
    }

    if (changes.isEmpty) return;

    setState(() => _busy = true);

    try {
      final callable = FirebaseFunctions.instance.httpsCallable('transferHeroResourcesFunction');
      await callable.call({
        'heroId': widget.hero.id,
        'tileKey': tileKey,
        'resourceChanges': changes,
      });

      await _loadResourceSource();
    } catch (e) {
      print("🔥 Failed to transfer all: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error transferring resources: $e")),
      );
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _transferCustom({required bool pickUp}) async {
    if (tileKey == null) return;

    final changes = <String, int>{};

    for (final key in sourceResources.keys) {
      final value = int.tryParse(_controllers[key]?.text ?? '0') ?? 0;
      if (value > 0) {
        changes[key] = pickUp ? value : -value;
      }
    }

    if (changes.isEmpty) return;

    setState(() => _busy = true);

    try {
      final callable = FirebaseFunctions.instance.httpsCallable('transferHeroResourcesFunction');
      await callable.call({
        'heroId': widget.hero.id,
        'tileKey': tileKey,
        'resourceChanges': changes,
      });

      await _loadResourceSource();
    } catch (e) {
      print("🔥 Failed to transfer custom resources: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error transferring resources: $e")),
      );
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final heroRes = widget.hero.carriedResources;
    final currentWeight = widget.hero.currentWeight ?? 0;
    final maxWeight = widget.hero.carryCapacity ?? 1;
    final percent = (currentWeight / maxWeight).clamp(0.0, 1.0);

    return _loading
        ? const Center(child: CircularProgressIndicator())
        : Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            insideVillage && villageId != null
                ? "🏰 Inside Village • Transfer from Storage"
                : "🗺️ On Tile • Transfer from Tile",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // ✅ Carry capacity bar
          Text(
            "⚖️ Carried Weight: ${currentWeight.toStringAsFixed(2)} / $maxWeight",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percent,
            minHeight: 8,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(
              percent < 0.5
                  ? Colors.green
                  : percent < 0.9
                  ? Colors.orange
                  : Colors.red,
            ),
          ),
          const SizedBox(height: 16),

          ..._buildResourceRows(heroRes),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.upload_file),
                label: const Text("Pick Up All"),
                onPressed: _busy ? null : () => _transferAll(pickUp: true),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.download),
                label: const Text("Drop All"),
                onPressed: _busy ? null : () => _transferAll(pickUp: false),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.upload),
                label: const Text("Pick Up Resources"),
                onPressed: _busy ? null : () => _transferCustom(pickUp: true),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.download_rounded),
                label: const Text("Drop Resources"),
                onPressed: _busy ? null : () => _transferCustom(pickUp: false),
              ),
            ],
          )
        ],
      ),
    );
  }


  List<Widget> _buildResourceRows(Map<String, dynamic> heroRes) {
    final keys = ['wood', 'stone', 'iron', 'food', 'gold'];
    return keys.map((key) {
      final heroAmount = heroRes[key] ?? 0;
      final sourceAmount = sourceResources[key] ?? 0;
      final emoji = _emojiFor(key);

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(width: 90, child: Text("$emoji ${_capitalize(key)}")),
            SizedBox(
              width: 70,
              child: TextField(
                controller: _controllers[key],
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "$heroAmount carried / $sourceAmount ${villageId != null ? 'in village' : 'on tile'}",
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  String _emojiFor(String resource) {
    switch (resource) {
      case 'wood':
        return '🪵';
      case 'stone':
        return '🪨';
      case 'iron':
        return '⛓';
      case 'food':
        return '🍗';
      case 'gold':
        return '🪙';
      default:
        return '❓';
    }
  }

  String _capitalize(String input) {
    return input[0].toUpperCase() + input.substring(1);
  }
}
