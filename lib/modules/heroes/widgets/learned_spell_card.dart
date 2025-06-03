import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roots_app/modules/heroes/views/assign_spell_screen.dart';

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
    final name = spell['name'] ?? 'Unknown';
    final description = spell['description'] ?? '';
    final type = spell['type'] ?? 'unknown';
    final manaCost = spell['manaCost'] ?? 0;
    final baseEffect = (spell['baseEffect'] ?? {}) as Map<String, dynamic>;
    final spellId = spell['id'] ?? spell['name']; // fallback if id is missing

    final conditionLabels = {
      'manaPercentageAbove': 'Mana > X%',
      'manaAbove': 'Mana > X',
      'enemiesInCombatMin': 'If enemy count ≥ X',
      'onlyIfEnemyHeroPresent': 'Only if enemy hero is present',
      'maxCastsPerFight': 'Only X casts per combat',
      'allyHpBelowPercentage': 'If ally HP < X%',
    };

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🧙‍♂️ Title row
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.blueAccent),
              const SizedBox(width: 8),
              Text(
                name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 📚 Description
          Text(description),
          const SizedBox(height: 8),
          Text(
            getTypeDescription(type),
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            'Mana Cost: $manaCost',
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          if (baseEffect.isNotEmpty)
            Text(
              getBaseEffectDescription(baseEffect),
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),

          // 🔍 Show assigned conditions if combat spell
          if (type == 'combat') ...[
            const SizedBox(height: 12),
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('heroes')
                  .doc(heroId)
                  .collection('assignedSpells')
                  .doc(spellId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Text(
                    'No conditions assigned.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  );
                }

                final data = snapshot.data!.data() as Map<String, dynamic>?;
                final conditions = data?['conditions'] as Map<String, dynamic>?;

                if (conditions == null || conditions.isEmpty) {
                  return const Text(
                    'No conditions assigned.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Assigned Conditions:',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
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
                          line = "Limit: cast at most $value time${value == 1 ? '' : 's'} per fight.";
                          break;
                        case 'allyHpBelowPercentage':
                          line = "If an ally's HP drops below $value%.";
                          break;
                        default:
                          line = "$key → $value";
                      }

                      return Text(
                        '• $line',
                        style: const TextStyle(fontSize: 13, color: Colors.black87),
                      );
                    }),
                  ],
                );
              },
            ),
          ],

          const SizedBox(height: 12),

          // 🎯 Action Button (replaced with live-aware builder)
          if (type == 'combat') ...[
            const SizedBox(height: 12),
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('heroes')
                  .doc(heroId)
                  .collection('assignedSpells')
                  .doc(spellId)
                  .snapshots(),
              builder: (context, snapshot) {
                final data = snapshot.data?.data() as Map<String, dynamic>?;
                final conditions = data?['conditions'] as Map<String, dynamic>?;

                final hasConditions = conditions != null && conditions.isNotEmpty;
                final buttonText = hasConditions ? 'Adjust Assignment' : 'Assign Spell';

                return Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade700,
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => Dialog(
                          backgroundColor: Colors.white,
                          insetPadding: const EdgeInsets.all(20),
                          child: SizedBox(
                            width: 500,
                            child: AssignSpellScreen(
                              heroId: heroId,
                              userId: userId,
                              spell: spell,
                              existingConditions: conditions ?? {}, // 👈 new param!
                            ),
                          ),
                        ),
                      );
                    },
                    child: Text(buttonText),
                  ),
                );
              },
            )
          ]
        ],
      ),
    );
  }
}
