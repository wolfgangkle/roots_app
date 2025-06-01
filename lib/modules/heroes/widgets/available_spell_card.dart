import 'package:flutter/material.dart';
import 'package:roots_app/modules/heroes/widgets/learn_spell_button.dart';

class AvailableSpellCard extends StatelessWidget {
  final Map<String, dynamic> spell;
  final bool isLearned;
  final bool isUnlocked;
  final String? heroId;
  final String? userId;

  const AvailableSpellCard({
    super.key,
    required this.spell,
    required this.isLearned,
    required this.isUnlocked,
    this.heroId,
    this.userId,
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

    final canLearn = isUnlocked && !isLearned && heroId != null && userId != null;

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
          // 🔮 Title
          Row(
            children: [
              Icon(
                isUnlocked ? Icons.lock_open : Icons.lock,
                color: isUnlocked ? Colors.orange : Colors.grey,
              ),
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

          // 📜 Description
          Text(description),
          const SizedBox(height: 8),
          Text(getTypeDescription(type), style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 4),
          Text('Mana Cost: $manaCost', style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 4),
          if (baseEffect.isNotEmpty)
            Text(getBaseEffectDescription(baseEffect), style: const TextStyle(fontSize: 13, color: Colors.grey)),

          const SizedBox(height: 12),

          // 🎯 Learn button
          if (canLearn)
            Align(
              alignment: Alignment.centerRight,
              child: LearnSpellButton(
                spellId: spell['id'],
                heroId: heroId!,
                userId: userId!,
                isEnabled: canLearn,
              ),
            ),
        ],
      ),
    );
  }
}
