import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:roots_app/modules/heroes/models/hero_group_model.dart';
import 'package:roots_app/modules/heroes/widgets/hero_group_movement_minimap.dart';
import 'package:roots_app/screens/controllers/main_content_controller.dart';

class FoundVillageScreen extends StatefulWidget {
  final HeroGroupModel group;

  const FoundVillageScreen({super.key, required this.group});

  @override
  State<FoundVillageScreen> createState() => _FoundVillageScreenState();
}

class _FoundVillageScreenState extends State<FoundVillageScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;

  Future<void> _submit() async {
    final name = _controller.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    final mainContentController = Provider.of<MainContentController>(context, listen: false);

    if (name.length < 3) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Village name must be at least 3 characters.')),
      );
      return;
    }

    final heroId = widget.group.leaderHeroId ?? widget.group.members.first;

    final confirmNeeded = heroId.startsWith('companion_');
    if (confirmNeeded) {
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
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Cancel"),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
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
        'heroId': heroId,
        'villageName': name,
      });

      messenger.showSnackBar(
        SnackBar(content: Text(result.data['message'] ?? 'Village created.')),
      );

      // ✅ Instead of popping the screen, reset back to welcome or default content
      mainContentController.reset();
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
            SizedBox(
              height: 300,
              child: HeroGroupMovementMiniMap(group: widget.group),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLength: 24,
              decoration: const InputDecoration(
                labelText: "Village Name",
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _submit(),
            ),
            if ((widget.group.leaderHeroId ?? widget.group.members.first).startsWith('companion_')) ...[
              const SizedBox(height: 8),
              const Text(
                "💡 Using a companion will permanently convert them into a village.",
                style: TextStyle(fontSize: 12, color: Colors.orange),
              ),
            ],
            const SizedBox(height: 16),
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
