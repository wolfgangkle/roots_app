import 'dart:async';
import 'package:flutter/material.dart';
import 'package:roots_app/modules/village/models/village_model.dart';
import 'package:roots_app/modules/village/widgets/upgrade_progress_indicator.dart';
import 'package:roots_app/modules/village/extensions/village_model_extension.dart';
import 'package:roots_app/modules/village/extensions/building_model_extension.dart';

class VillageCard extends StatefulWidget {
  final VillageModel village;
  final VoidCallback? onTap;

  const VillageCard({
    Key? key,
    required this.village,
    this.onTap,
  }) : super(key: key);

  @override
  _VillageCardState createState() => _VillageCardState();
}

class _VillageCardState extends State<VillageCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Set up a timer that fires every second to update simulated resources
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final res = widget.village.simulatedResources;
    final upgrade = widget.village.currentBuildJob;

    final prodWood = widget.village.buildings['woodcutter']?.productionPerHour ?? 0;
    final prodStone = widget.village.buildings['quarry']?.productionPerHour ?? 0;
    final prodFood = widget.village.buildings['farm']?.productionPerHour ?? 0;
    final prodIron = widget.village.buildings['ironmine']?.productionPerHour ?? 0;
    final prodGold = widget.village.buildings['goldmine']?.productionPerHour ?? 0;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🏰 Name + Coordinates
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '🏰 ${widget.village.name}',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text('📍 ${widget.village.tileX}, ${widget.village.tileY}'),
                ],
              ),
              const SizedBox(height: 8),
              // 📦 Resources with production
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('⛓️ Iron: ${res['iron']} (+$prodIron/h)'),
                  Text('🌲 Wood: ${res['wood']} (+$prodWood/h)'),
                  Text('🪨 Stone: ${res['stone']} (+$prodStone/h)'),
                  Text('🍞 Food: ${res['food']} (+$prodFood/h)'),
                  Text('💰 Gold: ${res['gold']} (+$prodGold/h)'),
                ],
              ),
              const SizedBox(height: 8),
              // ⏳ Upgrade progress indicator with building name
              if (upgrade != null) ...[
                Text(
                  'Upgrading: ${upgrade.buildingType}',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                UpgradeProgressIndicator(
                  startedAt: upgrade.startedAt,
                  endsAt: upgrade.startedAt.add(upgrade.duration),
                  villageId: widget.village.id,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
