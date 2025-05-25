import 'dart:async';
import 'package:flutter/material.dart';
import 'package:roots_app/modules/village/models/village_model.dart';
import 'package:roots_app/modules/village/widgets/upgrade_progress_indicator.dart';
import 'package:roots_app/modules/village/widgets/crafting_progress_indicator.dart';
import 'package:roots_app/modules/village/extensions/village_model_extension.dart';
import 'package:roots_app/modules/village/extensions/building_model_extension.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VillageCard extends StatefulWidget {
  final VillageModel village;
  final VoidCallback? onTap;

  const VillageCard({
    super.key,
    required this.village,
    this.onTap,
  });

  @override
  VillageCardState createState() => VillageCardState();
}

class VillageCardState extends State<VillageCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
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
    final crafting = widget.village.currentCraftingJob;

    final prodWood = widget.village.buildings['woodcutter']?.productionPerHour ?? 0;
    final prodStone = widget.village.buildings['quarry']?.productionPerHour ?? 0;
    final prodFood = widget.village.buildings['farm']?.productionPerHour ?? 0;
    final prodIron = widget.village.buildings['mine']?.productionPerHour ?? 0;
    final prodGold = widget.village.buildings['goldmine']?.productionPerHour ?? 0;

    final capacity = widget.village.storageCapacity;
    final secured = widget.village.securedResources;

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

              // 📊 Resource Table
              Table(
                columnWidths: const {
                  0: FixedColumnWidth(28),
                  1: FlexColumnWidth(),
                  2: FixedColumnWidth(140),
                  3: FixedColumnWidth(40),
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  _buildRow("🌲", "Wood", res["wood"], prodWood, capacity["wood"], secured["wood"],
                      widget.village.buildings['woodcutter']?.assignedWorkers),
                  _buildRow("🪨", "Stone", res["stone"], prodStone, capacity["stone"], secured["stone"],
                      widget.village.buildings['quarry']?.assignedWorkers),
                  _buildRow("⛓️", "Iron", res["iron"], prodIron, capacity["iron"], secured["iron"],
                      widget.village.buildings['mine']?.assignedWorkers),
                  _buildRow("🍞", "Food", res["food"], prodFood, capacity["food"], secured["food"],
                      widget.village.buildings['farm']?.assignedWorkers),
                  _buildRow("🪙", "Gold", res["gold"], prodGold, capacity["gold"], secured["gold"],
                      widget.village.buildings['goldmine']?.assignedWorkers),
                ],
              ),
              const SizedBox(height: 8),

              // ⏳ Upgrade progress
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

              // 🛠️ Crafting progress
              if (crafting != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Crafting: ${crafting['itemId'] ?? 'unknown'}',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                CraftingProgressIndicator(
                  startedAt: (crafting['startedAt'] as Timestamp).toDate(),
                  endsAt: (crafting['startedAt'] as Timestamp)
                      .toDate()
                      .add(Duration(seconds: crafting['durationSeconds'] ?? 0)),
                  villageId: widget.village.id,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  TableRow _buildRow(
      String emoji,
      String label,
      int? value,
      int production,
      int? cap,
      int? bunker,
      int? workers,
      ) {
    final prodText = '(${production} /h${workers != null ? ' • ${workers}w' : ''})';
    final capText = cap != null ? ' / $cap' : '';
    return TableRow(
      children: [
        Text(emoji),
        Text(label),
        Text('${value ?? 0} $prodText$capText'),
        Text('[${bunker ?? 0}]', textAlign: TextAlign.right),
      ],
    );
  }
}
