import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:roots_app/modules/heroes/widgets/learn_spell_button.dart';

// 🔷 Tokens
import 'package:roots_app/theme/app_style_manager.dart';
import 'package:roots_app/theme/widgets/token_panels.dart';
import 'package:roots_app/theme/tokens.dart';

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
    // 🔁 Tokens
    context.watch<StyleManager>();
    final glass = kStyle.glass;
    final text = kStyle.textOnGlass;
    final pad = kStyle.card.padding;

    final name = spell['name'] ?? 'Unknown';
    final description = spell['description'] ?? '';
    final type = spell['type'] ?? 'unknown';
    final manaCost = spell['manaCost'] ?? 0;
    final baseEffect = (spell['baseEffect'] ?? {}) as Map<String, dynamic>;

    final canLearn = isUnlocked && !isLearned && heroId != null && userId != null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      child: TokenPanel(
        glass: glass,
        text: text,
        padding: EdgeInsets.fromLTRB(pad.left, 12, pad.right, 12),
        child: Opacity(
          opacity: isUnlocked ? 1.0 : 0.66,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔮 Title row
              Row(
                children: [
                  Icon(
                    isUnlocked ? Icons.lock_open : Icons.lock,
                    size: 18,
                    color: isUnlocked ? text.primary : text.subtle,
                  ),
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

              // 📜 Description & meta
              if (description.toString().trim().isNotEmpty) ...[
                Text(
                  description,
                  style: TextStyle(color: text.secondary),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                getTypeDescription(type),
                style: TextStyle(fontSize: 13, color: text.secondary),
              ),
              const SizedBox(height: 4),
              Text(
                'Mana Cost: $manaCost',
                style: TextStyle(fontSize: 13, color: text.secondary),
              ),
              const SizedBox(height: 4),
              if (baseEffect.isNotEmpty)
                Text(
                  getBaseEffectDescription(baseEffect),
                  style: TextStyle(fontSize: 13, color: text.secondary),
                ),

              // 🎯 Learn button (kept as your existing widget)
              if (canLearn) ...[
                const SizedBox(height: 12),
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
            ],
          ),
        ),
      ),
    );
  }
}
