import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:roots_app/modules/village/models/village_model.dart';
import 'package:roots_app/modules/village/extensions/village_model_extension.dart';
import 'package:roots_app/modules/village/widgets/upgrade_progress_indicator.dart';
import 'package:roots_app/modules/village/widgets/crafting_progress_indicator.dart';
import 'package:roots_app/modules/village/data/building_definitions.dart';
import 'package:roots_app/modules/village/data/items.dart';

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

  String formatNumber(int value) {
    return NumberFormat.decimalPattern('de').format(value);
  }

  @override
  Widget build(BuildContext context) {
    final res = widget.village.simulatedResources;
    final cap = widget.village.storageCapacity;
    final secured = widget.village.securedResources;
    final upgrade = widget.village.currentBuildJob;
    final crafting = widget.village.currentCraftingJob;
    final freeWorkers = widget.village.freeWorkers;

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
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
                  2: FixedColumnWidth(80),
                  3: FixedColumnWidth(40),
                  4: FixedColumnWidth(60),
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  _buildRow("🌲", "Wood", "woodcutter", safeToInt(res["wood"]), safeToInt(cap["wood"]), safeToInt(secured["wood"]), freeWorkers),
                  _buildRow("🪨", "Stone", "quarry", safeToInt(res["stone"]), safeToInt(cap["stone"]), safeToInt(secured["stone"]), freeWorkers),
                  _buildRow("⛓️", "Iron", "iron_mine", safeToInt(res["iron"]), safeToInt(cap["iron"]), safeToInt(secured["iron"]), freeWorkers),
                  _buildRow("🍞", "Food", "farm", safeToInt(res["food"]), safeToInt(cap["food"]), safeToInt(secured["food"]), freeWorkers),
                  _buildRow("🪙", "Gold", "goldmine", safeToInt(res["gold"]), safeToInt(cap["gold"]), safeToInt(secured["gold"]), freeWorkers),
                ],
              ),

              const SizedBox(height: 8),

              // ⏳ Upgrade progress
              if (upgrade != null) ...[
                Text(
                  'Upgrading: ${_getBuildingDisplayName(upgrade.buildingType)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
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
                  'Crafting: ${_getItemName(crafting['itemId'])}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                CraftingProgressIndicator(
                  startedAt: (crafting['startedAt'] as Timestamp).toDate(),
                  endsAt: (crafting['startedAt'] as Timestamp).toDate().add(
                      Duration(seconds: crafting['durationSeconds'] ?? 0)),
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
      String buildingType,
      int value,
      int capacity,
      int secured,
      int freeWorkers,
      ) {
    final assigned = widget.village.buildings[buildingType]?.assignedWorkers ?? 0;
    final level = widget.village.buildings[buildingType]?.level ?? 0;

    final def = buildingDefinitions.cast<Map<String, dynamic>?>().firstWhere(
          (b) => b?['type'] == buildingType,
      orElse: () => null,
    );

    final workerPerLevel = def?['workerPerLevel'] as int? ?? 0;
    final maxAssignable = level * workerPerLevel;

    final isGold = buildingType == 'goldmine';
    final isFull = !isGold && capacity > 0 && value >= capacity;
    final canAssignMore = !isGold && assigned < maxAssignable && freeWorkers > 0;

    final resourceText = Text(
      formatNumber(value),
      textAlign: TextAlign.right,
      style: TextStyle(fontWeight: isFull ? FontWeight.bold : FontWeight.normal),
    );

    final workerText = isGold
        ? const Text('-', textAlign: TextAlign.right)
        : Text(
      '${assigned}w',
      textAlign: TextAlign.right,
      style: TextStyle(fontWeight: canAssignMore ? FontWeight.bold : FontWeight.normal),
    );

    final securedText = Text('[$secured]', textAlign: TextAlign.right);

    return TableRow(
      children: [
        Text(emoji),
        Text(label),
        resourceText,
        workerText,
        securedText,
      ],
    );
  }

  String _getBuildingDisplayName(String buildingType) {
    final def = buildingDefinitions
        .cast<Map<String, dynamic>?>()
        .firstWhere((b) => b?['type'] == buildingType, orElse: () => null);

    return def?['displayName']?['default'] ?? buildingType;
  }

  String _getItemName(String? itemId) {
    if (itemId == null) return 'unknown item';
    final def = gameItems[itemId];
    return def?['name'] ?? itemId;
  }
}
