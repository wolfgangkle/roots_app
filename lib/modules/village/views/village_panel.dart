import 'package:flutter/material.dart';
import 'package:roots_app/screens/dev/dev_mode.dart';
import 'package:roots_app/modules/village/services/village_service.dart';
import 'package:roots_app/modules/village/models/village_model.dart';
import 'package:roots_app/modules/village/widgets/village_card.dart';
import 'package:roots_app/modules/village/extensions/village_model_extension.dart';
import 'package:cloud_functions/cloud_functions.dart';

class VillagePanel extends StatefulWidget {
  final void Function(VillageModel)? onVillageTap;

  const VillagePanel({Key? key, this.onVillageTap}) : super(key: key);

  @override
  _VillagePanelState createState() => _VillagePanelState();
}

class _VillagePanelState extends State<VillagePanel> {
  final VillageService service = VillageService();

  Future<void> _createNewVillage() async {
    // Replace these dummy values with actual values from your game state:
    const dummyHeroId = 'hero_123'; // Replace with actual hero id
    const dummyTileX = 50;          // Replace with actual tile x-coordinate
    const dummyTileY = 350;         // Replace with actual tile y-coordinate

    final callable = FirebaseFunctions.instance.httpsCallable('foundVillage');
    try {
      final result = await callable.call({
        'heroId': dummyHeroId,
        'tileX': dummyTileX,
        'tileY': dummyTileY,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New village created successfully!')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating village: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<VillageModel>>(
      stream: service.getVillagesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        final villages = snapshot.data ?? [];

        if (villages.isEmpty) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("You don’t have any villages yet."),
              const SizedBox(height: 16),
              if (DevMode.enabled)
                ElevatedButton(
                  onPressed: _createNewVillage,
                  child: const Text("Create New Village"),
                ),
            ],
          );
        }

        return Column(
          children: [
            if (DevMode.enabled)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ElevatedButton.icon(
                  onPressed: _createNewVillage,
                  icon: const Icon(Icons.add),
                  label: const Text("Create New Village"),
                ),
              ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                separatorBuilder: (_, __) => const Divider(),
                itemCount: villages.length,
                itemBuilder: (context, index) {
                  final village = villages[index];
                  return VillageCard(
                    village: village,
                    onTap: () => widget.onVillageTap?.call(village),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
