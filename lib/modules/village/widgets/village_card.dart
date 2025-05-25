import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roots_app/modules/village/models/village_model.dart';
import 'package:roots_app/modules/village/extensions/village_model_extension.dart';
import 'package:roots_app/modules/village/widgets/upgrade_progress_indicator.dart';
import 'package:roots_app/modules/village/widgets/crafting_progress_indicator.dart';

class VillageCard extends StatefulWidget {
  final VillageModel village;
  final VoidCallback? onTap;

  const VillageCard({
    super.key,
    required this.village,
    this.onTap,
  });

  @override
  State<VillageCard> createState() => VillageCardState();
}

class VillageCardState extends State<VillageCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
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
    final prod = widget.village.currentProductionPerHour;
    final upgrade = widget.village.currentBuildJob;
    final crafting = widget.village.currentCraftingJob;
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
                  _buildRow("🌲", "Wood", (res["wood"] ?? 0).toInt(), (prod["wood"] ?? 0).toInt(), (capacity["wood"] ?? 0).toInt(), (secured["wood"] ?? 0).toInt(), widget.village.buildings['woodcutter']?.assignedWorkers ?? 0),
                  _buildRow("🪨", "Stone", (res["stone"] ?? 0).toInt(), (prod["stone"] ?? 0).toInt(), (capacity["stone"] ?? 0).toInt(), (secured["stone"] ?? 0).toInt(), widget.village.buildings['quarry']?.assignedWorkers ?? 0),
                  _buildRow("⛓️", "Iron", (res["iron"] ?? 0).toInt(), (prod["iron"] ?? 0).toInt(), (capacity["iron"] ?? 0).toInt(), (secured["iron"] ?? 0).toInt(), widget.village.buildings['mine']?.assignedWorkers ?? 0),
                  _buildRow("🍞", "Food", (res["food"] ?? 0).toInt(), (prod["food"] ?? 0).toInt(), (capacity["food"] ?? 0).toInt(), (secured["food"] ?? 0).toInt(), widget.village.buildings['farm']?.assignedWorkers ?? 0),
                  _buildRow("🪙", "Gold", (res["gold"] ?? 0).toInt(), (prod["gold"] ?? 0).toInt(), (capacity["gold"] ?? 0).toInt(), (secured["gold"] ?? 0).toInt(), widget.village.buildings['goldmine']?.assignedWorkers ?? 0),
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
      int value,
      int production,
      int capacity,
      int secured,
      int workers,
      ) {
    final prodText = '($production /h${workers > 0 ? ' • ${workers}w' : ''})';
    final capText = capacity > 0 ? ' / $capacity' : '';
    return TableRow(
      children: [
        Text(emoji),
        Text(label),
        Text('$value $prodText$capText'),
        Text('[$secured]', textAlign: TextAlign.right),
      ],
    );
  }
}
