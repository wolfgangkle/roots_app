import 'package:flutter/material.dart';
import '../services/village_service.dart';
import '../models/village_model.dart';
import '../widgets/village_card.dart';

class VillagePanel extends StatelessWidget {
  final void Function(VillageModel)? onVillageTap;

  const VillagePanel({super.key, this.onVillageTap});

  @override
  Widget build(BuildContext context) {
    final service = VillageService();

    return StreamBuilder<List<VillageModel>>(
      stream: service.getVillagesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        final rawVillages = snapshot.data ?? [];

        if (rawVillages.isEmpty) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("You don’t have any villages yet."),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  await service.createTestVillage();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Test village created!')),
                  );
                },
                child: const Text("Create Test Village"),
              ),
            ],
          );
        }

        // ✅ Check each village for pending upgrade
        return FutureBuilder<List<VillageModel>>(
          future: Future.wait(
            rawVillages.map(service.applyPendingUpgradeIfNeeded),
          ),
          builder: (context, futureSnapshot) {
            if (futureSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (futureSnapshot.hasError) {
              return Center(child: Text("Error: ${futureSnapshot.error}"));
            }

            final villages = futureSnapshot.data ?? [];

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await service.createTestVillage();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Test village created!')),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text("Create Test Village"),
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
                        onTap: () => onVillageTap?.call(village),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
