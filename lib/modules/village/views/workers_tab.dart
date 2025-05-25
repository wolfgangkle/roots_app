import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:roots_app/modules/village/data/building_definitions.dart';
import 'package:roots_app/modules/village/models/village_model.dart';
import 'package:roots_app/modules/village/services/village_service.dart';

class WorkersTab extends StatefulWidget {
  final String villageId;

  const WorkersTab({super.key, required this.villageId});

  @override
  State<WorkersTab> createState() => _WorkersTabState();
}

class _WorkersTabState extends State<WorkersTab> {
  final VillageService villageService = VillageService();
  bool _loading = false;
  final Map<String, int> _pendingAssignments = {};

  Future<void> _assign(String type, int newAmount) async {
    setState(() => _loading = true);
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('assignWorkerToBuilding');
      await callable.call({
        'villageId': widget.villageId,
        'buildingType': type,
        'assignedWorkers': newAmount,
      });
    } catch (e) {
      debugPrint("⚠️ Failed to assign workers: $e");
    } finally {
      setState(() {
        _loading = false;
        _pendingAssignments.remove(type); // reset after applied
      });
    }
  }

  Future<void> _fill(String type) async {
    setState(() => _loading = true);
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('assignWorkerToBuilding');
      await callable.call({
        'villageId': widget.villageId,
        'buildingType': type,
        'mode': 'fill',
      });
    } catch (e) {
      debugPrint("⚠️ Failed to fill workers: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _fillAll() async {
    setState(() => _loading = true);
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('assignWorkerToBuilding');
      await callable.call({
        'villageId': widget.villageId,
        'mode': 'fill_all',
      });
    } catch (e) {
      debugPrint("⚠️ Failed to fill all workers: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<VillageModel>(
      stream: villageService.watchVillage(widget.villageId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final village = snapshot.data!;
        final buildings = village.buildings;
        final free = village.freeWorkers;

        final rows = buildingDefinitions
            .where((entry) {
          final def = entry as Map<String, dynamic>;
          final type = def['type'] as String;
          final level = buildings[type]?.level ?? 0;

          return level > 0 &&
              def['provides']?['maxProductionPerHour'] != null &&
              def['workerPerLevel'] != null;
        })
            .map((entry) {
          final def = entry as Map<String, dynamic>;
          final type = def['type'] as String;
          final displayName = def['displayName']?['default'] as String? ?? type;
          final level = buildings[type]?.level ?? 0;
          final assigned = buildings[type]?.assignedWorkers ?? 0;
          final workerPerLevel = def['workerPerLevel'] as int? ?? 2;
          final max = level * workerPerLevel;

          final resourceMap = def['provides']['maxProductionPerHour'] as Map<String, dynamic>? ?? {};
          final resourceType = _getProducedResourceType(type);
          final productionBase = resourceMap[resourceType] as num? ?? 0;
          final tempAssigned = _pendingAssignments[type] ?? assigned;
          final totalBase = productionBase * level;
          final production = max == 0 ? 0 : (totalBase * (tempAssigned / max));


          return Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$displayName (Lv $level)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text('👷 $tempAssigned / $max | ⚒ ${production.toStringAsFixed(1)} per hour'),
                  Slider(
                    value: tempAssigned.toDouble(),
                    min: 0,
                    max: max.toDouble(),
                    divisions: max > 0 ? max : 1,
                    label: '$tempAssigned',
                    onChanged: _loading || max == 0
                        ? null
                        : (val) {
                      setState(() {
                        _pendingAssignments[type] = val.round();
                      });
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.build),
                        label: const Text('Fill'),
                        onPressed: _loading || assigned >= max || free <= 0
                            ? null
                            : () => _fill(type),
                      ),
                      if (_pendingAssignments[type] != null &&
                          _pendingAssignments[type] != assigned)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.check),
                          label: const Text('Apply'),
                          onPressed: _loading
                              ? null
                              : () => _assign(type, _pendingAssignments[type]!),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        })
            .toList();

        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text('Free Workers: $free', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _loading || free <= 0 ? null : _fillAll,
                icon: const Icon(Icons.groups),
                label: const Text("Auto-fill All"),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(children: rows),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getProducedResourceType(String buildingType) {
    const map = {
      'woodcutter': 'wood',
      'quarry': 'stone',
      'farm': 'food',
      'wheat_fields': 'food',
      'wheat_fields_large': 'food',
      'iron_mine': 'iron',
    };
    return map[buildingType] ?? 'unknown';
  }
}
