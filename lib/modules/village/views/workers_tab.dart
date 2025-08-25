import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:roots_app/modules/village/data/building_definitions.dart';
import 'package:roots_app/modules/village/models/village_model.dart';
import 'package:roots_app/modules/village/services/village_service.dart';

// 🔷 Tokens
import 'package:roots_app/theme/app_style_manager.dart';
import 'package:roots_app/theme/widgets/token_panels.dart';
import 'package:roots_app/theme/widgets/token_buttons.dart';
import 'package:roots_app/theme/tokens.dart';

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
      if (mounted) {
        setState(() {
          _loading = false;
          _pendingAssignments.remove(type); // reset after applied
        });
      }
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
      if (mounted) {
        setState(() => _loading = false);
      }
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
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔄 Live-reactive tokens
    context.watch<StyleManager>();
    final glass = kStyle.glass;
    final text = kStyle.textOnGlass;
    final buttons = kStyle.buttons;
    final cardPad = kStyle.card.padding;

    return StreamBuilder<VillageModel>(
      stream: villageService.watchVillage(widget.villageId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final village = snapshot.data!;
        final buildings = village.buildings;
        final free = village.freeWorkers;

        // Build eligible rows (has level and worker capacity + production)
        final rows = buildingDefinitions
            .where((raw) {
          final def = raw as Map<String, dynamic>;
          final type = def['type'] as String;
          final level = buildings[type]?.level ?? 0;
          return level > 0 &&
              def['provides']?['maxProductionPerHour'] != null &&
              def['workerPerLevel'] != null;
        })
            .map((raw) {
          final def = raw as Map<String, dynamic>;
          final type = def['type'] as String;
          final displayName = (def['displayName']?['default'] as String?) ?? type;
          final level = buildings[type]?.level ?? 0;
          final assigned = buildings[type]?.assignedWorkers ?? 0;
          final workerPerLevel = def['workerPerLevel'] as int? ?? 2;
          final max = level * workerPerLevel;

          final resourceMap =
              def['provides']['maxProductionPerHour'] as Map<String, dynamic>? ?? {};
          final resourceType = _getProducedResourceType(type);
          final productionBase = (resourceMap[resourceType] as num?) ?? 0;
          final tempAssigned = _pendingAssignments[type] ?? assigned;
          final totalBase = productionBase * level;
          final production = max == 0 ? 0 : (totalBase * (tempAssigned / (max == 0 ? 1 : max)));

          return TokenPanel(
            glass: glass,
            text: text,
            padding: EdgeInsets.fromLTRB(cardPad.left, 12, cardPad.right, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  '$displayName (Lv $level)',
                  style: TextStyle(
                    color: text.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                // Meta line
                Text(
                  '👷 $tempAssigned / $max   •   ⚒ ${production.toStringAsFixed(1)} / h',
                  style: TextStyle(color: text.secondary),
                ),
                const SizedBox(height: 6),

                // Slider
                _tokenSlider(
                  value: tempAssigned.toDouble(),
                  max: max.toDouble().clamp(1, double.infinity),
                  divisions: max > 0 ? max : 1,
                  label: '$tempAssigned',
                  enabled: !_loading && max > 0,
                  glass: glass,
                  text: text,
                  onChanged: (val) {
                    setState(() {
                      _pendingAssignments[type] = val.round();
                    });
                  },
                ),

                const SizedBox(height: 6),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TokenIconButton(
                      glass: glass,
                      text: text,
                      buttons: buttons,
                      variant: TokenButtonVariant.subdued,
                      icon: const Icon(Icons.build),
                      label: const Text('Fill'),
                      onPressed:
                      _loading || assigned >= max || free <= 0 ? null : () => _fill(type),
                    ),
                    if (_pendingAssignments[type] != null &&
                        _pendingAssignments[type] != assigned)
                      TokenIconButton(
                        glass: glass,
                        text: text,
                        buttons: buttons,
                        variant: TokenButtonVariant.primary,
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
          );
        }).toList();

        return Padding(
          padding: EdgeInsets.fromLTRB(cardPad.left, 12, cardPad.right, cardPad.bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header panel: free workers + autofill
              TokenPanel(
                glass: glass,
                text: text,
                padding: EdgeInsets.fromLTRB(cardPad.left, 12, cardPad.right, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Free Workers: $free',
                        style: TextStyle(
                          color: text.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TokenIconButton(
                      glass: glass,
                      text: text,
                      buttons: buttons,
                      variant: TokenButtonVariant.primary,
                      icon: const Icon(Icons.groups),
                      label: const Text("Auto-fill All"),
                      onPressed: _loading || free <= 0 ? null : _fillAll,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Rows or loader
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : (rows.isEmpty
                    ? TokenPanel(
                  glass: glass,
                  text: text,
                  padding:
                  EdgeInsets.fromLTRB(cardPad.left, 14, cardPad.right, 14),
                  child: Text(
                    'No worker-managed buildings yet.',
                    style: TextStyle(color: text.secondary),
                  ),
                )
                    : ListView.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => rows[i],
                )),
              ),
            ],
          ),
        );
      },
    );
  }

  // Slider styled to sit nicely on glass; avoids custom colors unless necessary.
  Widget _tokenSlider({
    required double value,
    required double max,
    required int divisions,
    required String label,
    required bool enabled,
    required GlassTokens glass,
    required TextOnGlassTokens text,
    required ValueChanged<double> onChanged,
  }) {
    final base =
    glass.baseColor.withValues(alpha: glass.mode == SurfaceMode.solid ? 0.10 : 0.08);
    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 6,
          inactiveTrackColor: base,
          overlayShape: SliderComponentShape.noThumb,
          valueIndicatorTextStyle: TextStyle(color: text.primary),
        ),
        child: Slider(
          value: value.clamp(0, max).toDouble(),
          min: 0,
          max: max,
          divisions: divisions,
          label: label,
          onChanged: enabled ? onChanged : null,
        ),
      ),
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
