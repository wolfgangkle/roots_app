import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

class AssignSpellScreen extends StatefulWidget {
  final Map<String, dynamic> spell;
  final String heroId;
  final String userId;
  final Map<String, dynamic> existingConditions;

  const AssignSpellScreen({
    super.key,
    required this.spell,
    required this.heroId,
    required this.userId,
    this.existingConditions = const {},
  });

  @override
  State<AssignSpellScreen> createState() => _AssignSpellScreenState();
}

class _AssignSpellScreenState extends State<AssignSpellScreen> {
  final Map<String, dynamic> _conditions = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _conditions.addAll(widget.existingConditions);
  }

  void _openConditionDialog() {
    String? selectedKey;
    dynamic selectedValue;

    final conditionOptions = {
      'manaPercentageAbove': 'Mana > X%',
      'manaAbove': 'Mana > X',
      'enemiesInCombatMin': 'If enemy count ≥ X',
      'onlyIfEnemyHeroPresent': 'Only if enemy hero is present',
      'maxCastsPerFight': 'Only X casts per combat',
      'allyHpBelowPercentage': 'If ally HP < X%',
    };

    final descriptions = {
      'manaPercentageAbove': 'Trigger if current mana is above given percent.',
      'manaAbove': 'Trigger if current mana is above the raw amount.',
      'enemiesInCombatMin': 'Trigger if there are at least X enemies.',
      'onlyIfEnemyHeroPresent': 'Trigger only if another player is in the fight.',
      'maxCastsPerFight': 'Maximum number of times to cast this spell per combat.',
      'allyHpBelowPercentage': 'Trigger if any ally has less than X% HP.',
    };

    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(
              selectedKey == null ? 'Choose Condition Type' : 'Set Condition Value',
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selectedKey == null)
                  ...conditionOptions.entries.map(
                        (entry) => ListTile(
                      title: Text(entry.value),
                      subtitle: Text(descriptions[entry.key]!),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        setDialogState(() {
                          selectedKey = entry.key;
                          selectedValue = entry.key == 'onlyIfEnemyHeroPresent' ? true : null;
                          controller.text = '';
                        });
                      },
                    ),
                  )
                else ...[
                  Text(
                    descriptions[selectedKey!] ?? '',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  if (selectedKey == 'onlyIfEnemyHeroPresent') ...[
                    const Text('This condition will only trigger if an enemy hero is present.'),
                    const SizedBox(height: 12),
                    const Icon(Icons.info_outline, size: 20, color: Colors.grey),
                  ]
                  else
                    TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        labelText: 'Enter value',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        final parsed = int.tryParse(value);
                        if (parsed != null) {
                          setDialogState(() => selectedValue = parsed);
                        }
                      },
                    ),
                ],
              ],
            ),
            actions: [
              if (selectedKey != null)
                TextButton(
                  onPressed: () => setDialogState(() {
                    selectedKey = null;
                    selectedValue = null;
                  }),
                  child: const Text('← Back'),
                ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              if (selectedKey != null)
                ElevatedButton(
                  onPressed: selectedKey != null &&
                      (selectedKey == 'onlyIfEnemyHeroPresent' ||
                          (selectedValue != null &&
                              selectedValue is int &&
                              selectedValue > 0 &&
                              (selectedKey!.contains('Percentage')
                                  ? selectedValue <= 100
                                  : true)))
                      ? () {
                    setState(() {
                      _conditions[selectedKey!] = selectedValue;
                    });
                    Navigator.of(context).pop();
                  }
                      : null,
                  child: const Text('Save'),
                ),
            ],
          );
        });
      },
    );
  }

  Future<void> _handleRemoveAssignment() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Assignment'),
        content: const Text('Are you sure you want to remove this spell assignment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFunctions.instance
          .httpsCallable('removeAssignedSpellFromHero')
          .call({
        'heroId': widget.heroId,
        'spellId': widget.spell['id'] ?? widget.spell['name'],
      });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🗑️ Spell assignment removed.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('⚠️ Failed to remove: $e')),
        );
      }
    }
  }

  void _handleSave() async {
    if (_saving) return;
    setState(() => _saving = true);

    final spellId = widget.spell['id'] ?? widget.spell['name'];

    try {
      await FirebaseFunctions.instance
          .httpsCallable('assignSpellToHero')
          .call({
        'heroId': widget.heroId,
        'spellId': spellId,
        'conditions': _conditions,
      });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Spell assignment saved successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('⚠️ Failed to save assignment: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final spell = widget.spell;
    final name = spell['name'] ?? 'Unknown';
    final description = spell['description'] ?? 'No description';
    final type = spell['type'] ?? 'combat';
    final manaCost = spell['manaCost'] ?? 0;

    final labels = {
      'manaPercentageAbove': 'Mana > X%',
      'manaAbove': 'Mana > X',
      'enemiesInCombatMin': 'If enemy count ≥ X',
      'onlyIfEnemyHeroPresent': 'Only if enemy hero is present',
      'maxCastsPerFight': 'Only X casts per combat',
      'allyHpBelowPercentage': 'If ally HP < X%',
    };

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Assign: $name',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(description),
          const SizedBox(height: 8),
          Text('Type: $type', style: const TextStyle(color: Colors.grey)),
          Text('Mana Cost: $manaCost', style: const TextStyle(color: Colors.grey)),
          const Divider(height: 32),
          Text('🎯 Conditions', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          if (_conditions.isEmpty)
            const Text('No conditions set yet.')
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _conditions.entries.map((entry) {
                final label = labels[entry.key] ?? entry.key;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(child: Text('$label → ${entry.value}')),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        onPressed: () => setState(() => _conditions.remove(entry.key)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _openConditionDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Condition'),
          ),
          const SizedBox(height: 32),
          Align(
            alignment: Alignment.centerRight,
            child: _conditions.isEmpty
                ? TextButton.icon(
              onPressed: _saving ? null : _handleRemoveAssignment,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Remove Assignment'),
            )
                : ElevatedButton.icon(
              onPressed: _saving ? null : _handleSave,
              icon: _saving
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : const Icon(Icons.check),
              label: Text(_saving ? 'Saving...' : 'Save Assignment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo.shade700,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
