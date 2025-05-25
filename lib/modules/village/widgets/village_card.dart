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

  int safeToInt(num? value) {
    if (value == null || value.isNaN || value == double.infinity || value == double.negativeInfinity) {
      return 0;
    }
    return value.toInt();
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
                  _buildRow("🌲", "Wood", safeToInt(res["wood"]), safeToInt(prod["wood"]), safeToInt(capacity["wood"]), safeToInt(secured["wood"]), widget.village.buildings['woodcutter']?.assignedWorkers ?? 0),
                  _buildRow("🪨", "Stone", safeToInt(res["stone"]), safeToInt(prod["stone"]), safeToInt(capacity["stone"]), safeToInt(secured["stone"]), widget.village.buildings['quarry']?.assignedWorkers ?? 0),
                  _buildRow("⛓️", "Iron", safeToInt(res["iron"]), safeToInt(prod["iron"]), safeToInt(capacity["iron"]), safeToInt(secured["iron"]), widget.village.buildings['mine']?.assignedWorkers ?? 0),
                  _buildRow("🍞", "Food", safeToInt(res["food"]), safeToInt(prod["food"]), safeToInt(capacity["food"]), safeToInt(secured["food"]), widget.village.buildings['farm']?.assignedWorkers ?? 0),
                  _buildRow("🪙", "Gold", safeToInt(res["gold"]), safeToInt(prod["gold"]), safeToInt(capacity["gold"]), safeToInt(secured["gold"]), widget.village.buildings['goldmine']?.assignedWorkers ?? 0),
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
