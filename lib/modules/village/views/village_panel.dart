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

        final villages = snapshot.data ?? [];

        if (villages.isEmpty) {
          return const Center(child: Text("You don’t have any villages yet."));
        }

        return ListView.separated(
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
        );
      },
    );
  }
}
