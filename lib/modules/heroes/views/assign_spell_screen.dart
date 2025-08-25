import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:provider/provider.dart';

// 🔷 Tokens
import 'package:roots_app/theme/app_style_manager.dart';
import 'package:roots_app/theme/widgets/token_panels.dart';
import 'package:roots_app/theme/widgets/token_buttons.dart';

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

  Future<void> _openConditionDialog() async {
    // 🔁 live tokens
    context.read<StyleManager>();
    final glass = kStyle.glass;
    final text = kStyle.textOnGlass;
    final buttons = kStyle.buttons;
    final pad = kStyle.card.padding;

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
      'manaPercentageAbove': 'Trigger if current mana is above a given percent.',
      'manaAbove': 'Trigger if current mana is above the raw amount.',
      'enemiesInCombatMin': 'Trigger if there are at least X enemies.',
      'onlyIfEnemyHeroPresent': 'Trigger only if another player is in the fight.',
      'maxCastsPerFight': 'Maximum number of times to cast this spell per combat.',
      'allyHpBelowPercentage': 'Trigger if any ally has less than X% HP.',
    };

    final controller = TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: StatefulBuilder(
              builder: (context, setDialogState) {
                return TokenPanel(
                  glass: glass,
                  text: text,
                  padding: EdgeInsets.fromLTRB(pad.left, 14, pad.right, 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              selectedKey == null
                                  ? 'Choose Condition Type'
                                  : 'Set Condition Value',
                              style: TextStyle(
                                color: text.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          TokenTextButton(
                            glass: glass,
                            text: text,
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      if (selectedKey == null) ...[
                        // Picker list
                        ...conditionOptions.entries.map(
                              (entry) => ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              entry.value,
                              style: TextStyle(color: text.primary),
                            ),
                            subtitle: Text(
                              descriptions[entry.key]!,
                              style: TextStyle(color: text.subtle, fontSize: 12),
                            ),
                            trailing: Icon(Icons.arrow_forward_ios, size: 14, color: text.secondary),
                            onTap: () {
                              setDialogState(() {
                                selectedKey = entry.key;
                                selectedValue = entry.key == 'onlyIfEnemyHeroPresent' ? true : null;
                                controller.text = '';
                              });
                            },
                          ),
                        ),
                      ] else ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            descriptions[selectedKey!] ?? '',
                            style: TextStyle(fontSize: 13, color: text.secondary),
                          ),
                        ),
                        const SizedBox(height: 12),

                        if (selectedKey == 'onlyIfEnemyHeroPresent') ...[
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'This condition will only trigger if an enemy hero is present.',
                              style: TextStyle(color: text.secondary),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Icon(Icons.info_outline, size: 20, color: text.subtle),
                        ] else
                          TextField(
                            controller: controller,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Enter value',
                              hintText: selectedKey!.contains('Percentage') ? '1–100' : 'Enter a number',
                              border: const OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              final parsed = int.tryParse(value);
                              setDialogState(() => selectedValue = parsed);
                            },
                          ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            TokenTextButton(
                              glass: glass,
                              text: text,
                              onPressed: () => setDialogState(() {
                                selectedKey = null;
                                selectedValue = null;
                                controller.text = '';
                              }),
                              child: const Text('← Back'),
                            ),
                            const Spacer(),
                            TokenTextButton(
                              glass: glass,
                              text: text,
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 6),
                            TokenIconButton(
                              glass: glass,
                              text: text,
                              variant: TokenButtonVariant.primary,
                              icon: const Icon(Icons.check),
                              label: const Text('Save'),
                              onPressed: selectedKey != null &&
                                  (selectedKey == 'onlyIfEnemyHeroPresent' ||
                                      (selectedValue != null &&
                                          selectedValue is int &&
                                          selectedValue > 0 &&
                                          (selectedKey!.contains('Percentage')
                                              ? (selectedValue as int) <= 100
                                              : true)))
                                  ? () {
                                setState(() {
                                  _conditions[selectedKey!] = selectedValue;
                                });
                                Navigator.of(context).pop();
                              }
                                  : null,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );

    controller.dispose();
  }

  Future<void> _handleRemoveAssignment() async {
    // 🔁 live tokens
    context.read<StyleManager>();
    final glass = kStyle.glass;
    final text = kStyle.textOnGlass;
    final pad = kStyle.card.padding;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: TokenPanel(
            glass: glass,
            text: text,
            padding: EdgeInsets.fromLTRB(pad.left, 14, pad.right, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Remove Assignment',
                        style: TextStyle(
                          color: text.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    TokenTextButton(
                      glass: glass,
                      text: text,
                      onPressed: () => Navigator.pop(context, false),
                      child: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Are you sure you want to remove this spell assignment?',
                    style: TextStyle(color: text.secondary),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TokenTextButton(
                      glass: glass,
                      text: text,
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 6),
                    TokenTextButton(
                      glass: glass,
                      text: text,
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Remove'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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

  Future<void> _handleSave() async {
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
    // 🔁 live tokens
    context.watch<StyleManager>();
    final glass = kStyle.glass;
    final text = kStyle.textOnGlass;
    final buttons = kStyle.buttons;
    final pad = kStyle.card.padding;

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

    return TokenPanel(
      glass: glass,
      text: text,
      padding: EdgeInsets.fromLTRB(pad.left, 14, pad.right, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  'Assign: $name',
                  style: TextStyle(
                    color: text.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              TokenTextButton(
                glass: glass,
                text: text,
                onPressed: () => Navigator.of(context).pop(),
                child: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(description, style: TextStyle(color: text.secondary)),
          const SizedBox(height: 6),
          Text('Type: $type', style: TextStyle(color: text.subtle, fontSize: 13)),
          Text('Mana Cost: $manaCost', style: TextStyle(color: text.subtle, fontSize: 13)),
          const SizedBox(height: 12),
          TokenDivider(glass: glass, text: text),

          const SizedBox(height: 10),
          Text('🎯 Conditions',
              style: TextStyle(
                color: text.primary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              )),
          const SizedBox(height: 10),

          if (_conditions.isEmpty)
            Text('No conditions set yet.', style: TextStyle(color: text.secondary))
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _conditions.entries.map((entry) {
                final label = labels[entry.key] ?? entry.key;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$label → ${entry.value}',
                          style: TextStyle(color: text.primary),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        color: Colors.redAccent,
                        tooltip: 'Remove condition',
                        onPressed: () => setState(() => _conditions.remove(entry.key)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TokenIconButton(
              glass: glass,
              text: text,
              buttons: buttons,
              variant: TokenButtonVariant.outline,
              icon: const Icon(Icons.add),
              label: const Text('Add Condition'),
              onPressed: _openConditionDialog,
            ),
          ),

          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (_conditions.isEmpty)
                TokenTextButton(
                  glass: glass,
                  text: text,
                  onPressed: _saving ? null : _handleRemoveAssignment,
                  child: const Text('Remove Assignment'),
                ),
              const SizedBox(width: 8),
              TokenIconButton(
                glass: glass,
                text: text,
                buttons: buttons,
                variant: TokenButtonVariant.primary,
                icon: _saving
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Icon(Icons.check),
                label: Text(_saving ? 'Saving...' : 'Save Assignment'),
                onPressed: _saving ? null : _handleSave,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
