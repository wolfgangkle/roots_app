import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roots_app/modules/heroes/views/assign_spell_screen.dart';

// 🔷 Tokens
import 'package:provider/provider.dart';
import 'package:roots_app/theme/app_style_manager.dart';
import 'package:roots_app/theme/widgets/token_panels.dart';
import 'package:roots_app/theme/widgets/token_buttons.dart';

class LearnedSpellCard extends StatelessWidget {
  final Map<String, dynamic> spell;
  final String heroId;
  final String userId;

  const LearnedSpellCard({
    super.key,
    required this.spell,
    required this.heroId,
    required this.userId,
  });

  String getTypeDescription(String type) {
    switch (type) {
      case 'combat':
        return 'Type: Combat Spell – Cast automatically during combat.';
      case 'buff':
        return 'Type: Buff – Long-lasting effect outside of combat.';
      case 'utility':
        return 'Type: Utility – Manual spell for healing or support.';
      default:
        return 'Type: Unknown';
    }
  }

  String getBaseEffectDescription(Map<String, dynamic> baseEffect) {
    final lines = <String>[];
    baseEffect.forEach((key, value) {
      switch (key) {
        case 'damage':
          lines.add('Deals $value damage.');
          break;
        case 'heal':
          lines.add('Restores $value HP.');
          break;
        case 'speedBoost':
          lines.add('Increases speed by ${(value * 100).toStringAsFixed(0)}%.');
          break;
        case 'armorBonus':
          lines.add('Grants $value armor.');
          break;
        case 'durationMinutes':
          lines.add('Lasts $value minutes.');
          break;
        case 'durationTicks':
          lines.add('Lasts $value combat ticks.');
          break;
        case 'hp':
          lines.add('Summoned creature has $value HP.');
          break;
        default:
          lines.add('$key: $value');
      }
    });
    return lines.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    // 🔁 Tokens
    context.watch<StyleManager>();
    final glass = kStyle.glass;
    final text = kStyle.textOnGlass;
    final buttons = kStyle.buttons;
    final pad = kStyle.card.padding;

    final name = spell['name'] ?? 'Unknown';
    final description = spell['description'] ?? '';
    final type = spell['type'] ?? 'unknown';
    final manaCost = spell['manaCost'] ?? 0;
    final baseEffect = (spell['baseEffect'] ?? {}) as Map<String, dynamic>;
    final spellId = (spell['id'] ?? spell['name']).toString(); // fallback if id missing

    final docStream = FirebaseFirestore.instance
        .collection('heroes')
        .doc(heroId)
        .collection('assignedSpells')
        .doc(spellId)
        .snapshots();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TokenPanel(
        glass: glass,
        text: text,
        padding: EdgeInsets.fromLTRB(pad.left, 12, pad.right, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🧙‍♂️ Title row
            Row(
              children: [
                const Icon(Icons.auto_awesome),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      color: text.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 📚 Description + meta
            if (description.toString().trim().isNotEmpty) ...[
              Text(description, style: TextStyle(color: text.secondary)),
              const SizedBox(height: 8),
            ],
            Text(getTypeDescription(type), style: TextStyle(fontSize: 13, color: text.secondary)),
            const SizedBox(height: 4),
            Text('Mana Cost: $manaCost', style: TextStyle(fontSize: 13, color: text.secondary)),
            const SizedBox(height: 4),
            if (baseEffect.isNotEmpty)
              Text(getBaseEffectDescription(baseEffect),
                  style: TextStyle(fontSize: 13, color: text.secondary)),

            if (type == 'combat') ...[
              const SizedBox(height: 12),

              // 🔍 Assigned conditions + action (single stream)
              StreamBuilder<DocumentSnapshot>(
                stream: docStream,
                builder: (context, snapshot) {
                  final data = snapshot.data?.data() as Map<String, dynamic>?;
                  final conditions = data?['conditions'] as Map<String, dynamic>?;

                  final hasConditions = conditions != null && conditions.isNotEmpty;
                  final buttonText = hasConditions ? 'Adjust Assignment' : 'Assign Spell';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!hasConditions)
                        Text('No conditions assigned.',
                            style: TextStyle(fontSize: 13, color: text.secondary))
                      else ...[
                        const Text('Assigned Conditions:',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        ...conditions.entries.map((entry) {
                          final key = entry.key;
                          final value = entry.value;
                          String line;
                          switch (key) {
                            case 'manaPercentageAbove':
                              line = "If the caster's mana is above $value%.";
                              break;
                            case 'manaAbove':
                              line = "If the caster's mana is above $value.";
                              break;
                            case 'enemiesInCombatMin':
                              line = "If there are at least $value enemies in the fight.";
                              break;
                            case 'onlyIfEnemyHeroPresent':
                              line = "Only if an enemy hero is present.";
                              break;
                            case 'maxCastsPerFight':
                              line =
                              "Limit: cast at most $value time${value == 1 ? '' : 's'} per fight.";
                              break;
                            case 'allyHpBelowPercentage':
                              line = "If an ally's HP drops below $value%.";
                              break;
                            default:
                              line = "$key → $value";
                          }
                          return Text('• $line',
                              style: TextStyle(fontSize: 13, color: text.primary));
                        }),
                      ],

                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TokenIconButton(
                          glass: glass,
                          text: text,
                          buttons: buttons,
                          variant: TokenButtonVariant.primary,
                          icon: const Icon(Icons.edit),
                          label: Text(buttonText),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => Dialog(
                                backgroundColor: Colors.transparent,
                                insetPadding: const EdgeInsets.all(20),
                                child: Center(
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 560),
                                    child: TokenPanel(
                                      glass: glass,
                                      text: text,
                                      padding: const EdgeInsets.all(16),
                                      child: AssignSpellScreen(
                                        heroId: heroId,
                                        userId: userId,
                                        spell: spell,
                                        existingConditions: conditions ?? {},
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
