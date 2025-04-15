import 'package:flutter/material.dart';
import 'package:roots_app/modules/village/services/village_service.dart';
import 'package:roots_app/modules/village/models/village_model.dart';
import 'package:roots_app/modules/village/widgets/village_card.dart';
import 'package:roots_app/modules/village/extensions/village_model_extension.dart';

class VillagePanel extends StatefulWidget {
  final void Function(VillageModel)? onVillageTap;

  const VillagePanel({Key? key, this.onVillageTap}) : super(key: key);

  @override
  _VillagePanelState createState() => _VillagePanelState();
}

class _VillagePanelState extends State<VillagePanel> {
  final VillageService service = VillageService();

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
              onTap: () => widget.onVillageTap?.call(village),
            );
          },
        );
      },
    );
  }
}
