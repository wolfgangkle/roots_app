import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:roots_app/modules/heroes/models/hero_model.dart';
import 'package:roots_app/modules/heroes/widgets/hero_mini_map_overlay.dart';

class FoundVillageScreen extends StatefulWidget {
  final HeroModel hero;

  const FoundVillageScreen({super.key, required this.hero});

  @override
  State<FoundVillageScreen> createState() => _FoundVillageScreenState();
}

class _FoundVillageScreenState extends State<FoundVillageScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;

  Future<void> _submit() async {
    final name = _controller.text.trim();
    final messenger = ScaffoldMessenger.of(context); // ✅ capture early
    final navigator = Navigator.of(context);         // ✅ capture early

    if (name.length < 3) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Village name must be at least 3 characters.')),
      );
      return;
    }

    if (widget.hero.type == 'companion') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Convert Companion to Village"),
          content: const Text(
            "Are you sure you want to found a village with this companion?\n\n"
                "This will permanently remove them.",
          ),
          actions: [
            TextButton(
              onPressed: () => navigator.pop(false),
              child: const Text("Cancel"),
            ),
            ElevatedButton.icon(
              onPressed: () => navigator.pop(true),
              icon: const Icon(Icons.check),
              label: const Text("Yes, Convert"),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    setState(() => _isLoading = true);

    try {
      final callable = FirebaseFunctions.instance.httpsCallable('createVillage');
      final result = await callable.call({
        'heroId': widget.hero.id,
        'villageName': name,
      });

      messenger.showSnackBar(
        SnackBar(content: Text(result.data['message'] ?? 'Village created.')),
      );

      navigator.pop(); // Go back to hero screen
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Found New Village")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// 🗺️ Tactical minimap showing current hero position
            SizedBox(
              height: 300,
              child: HeroMiniMapOverlay(
                hero: widget.hero,
                waypoints: [],
                centerTileOffset: Offset(
                    widget.hero.tileX.toDouble(), widget.hero.tileY.toDouble()),
              ),
            ),
            const SizedBox(height: 16),

            /// 🏷️ Village Name Input
            TextField(
              controller: _controller,
              maxLength: 24,
              decoration: const InputDecoration(
                labelText: "Village Name",
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _submit(),
            ),

            if (widget.hero.type == 'companion') ...[
              const SizedBox(height: 8),
              const Text(
                "💡 Using a companion will permanently convert them into a village.",
                style: TextStyle(fontSize: 12, color: Colors.orange),
              ),
            ],

            const SizedBox(height: 16),

            /// ✅ Found Button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _submit,
              icon: const Icon(Icons.flag),
              label: _isLoading
                  ? const Text("Founding Village...")
                  : const Text("Found Village"),
            ),
          ],
        ),
      ),
    );
  }
}
