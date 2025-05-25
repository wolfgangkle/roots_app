import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:roots_app/modules/village/models/village_model.dart';
import 'package:roots_app/modules/village/data/building_definitions.dart';

class WorkersTab extends StatefulWidget {
  final VillageModel village;

  const WorkersTab({super.key, required this.village});

  @override
  State<WorkersTab> createState() => _WorkersTabState();
}

class _WorkersTabState extends State<WorkersTab> {
  bool _loading = false;

  Future<void> _assign(String type, int newAmount) async {
    setState(() => _loading = true);
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('assignWorkerToBuilding');
      await callable.call({
        'villageId': widget.village.id,
        'buildingType': type,
        'assignedWorkers': newAmount,
      });
    } catch (e) {
      debugPrint("⚠️ Failed to assign workers: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _fill(String type) async {
    setState(() => _loading = true);
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('assignWorkerToBuilding');
      await callable.call({
        'villageId': widget.village.id,
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
        'villageId': widget.village.id,
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
    final buildings = widget.village.buildings;
    final free = widget.village.freeWorkers;

    final rows = buildingDefinitions
        .where((entry) {
      final def = entry as Map<String, dynamic>;
      return def['provides']?['maxProductionPerHour'] != null && def['workerPerLevel'] != null;
    })
        .map((entry) {
      final def = entry as Map<String, dynamic>;
      final type = def['type'] as String;
      final displayName = def['displayName']?['default'] as String? ?? type;
      final level = buildings[type]?.level ?? 0;
      final assigned = buildings[type]?.assignedWorkers ?? 0;
      final workerPerLevel = def['workerPerLevel'] as int? ?? 2;
      final max = level * workerPerLevel;

      return Card(
        child: ListTile(
          title: Text('$displayName (Lv $level)'),
          subtitle: Text('👷 $assigned / $max'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: _loading || assigned <= 0
                    ? null
                    : () => _assign(type, assigned - 1),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _loading || assigned >= max || free <= 0
                    ? null
                    : () => _assign(type, assigned + 1),
              ),
              IconButton(
                icon: const Icon(Icons.build),
                tooltip: 'Fill',
                onPressed: _loading || assigned >= max || free <= 0
                    ? null
                    : () => _fill(type),
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
  }
}
