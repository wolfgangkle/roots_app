import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:roots_app/modules/heroes/models/hero_model.dart';
import 'package:roots_app/modules/heroes/models/hero_group_model.dart';
import 'package:roots_app/modules/heroes/widgets/hero_movement_card.dart';
import 'package:roots_app/modules/heroes/widgets/hero_weight_bar.dart';
import 'package:roots_app/modules/heroes/views/found_village_screen.dart';
import 'package:roots_app/screens/controllers/main_content_controller.dart';

// 🔷 Tokens
import 'package:roots_app/theme/app_style_manager.dart';
import 'package:roots_app/theme/widgets/token_panels.dart';
import 'package:roots_app/theme/widgets/token_buttons.dart';
import 'package:roots_app/theme/tokens.dart';

// 🔗 Level-up inline wiring
import 'package:roots_app/modules/heroes/controllers/level_up_controller.dart';
import 'package:roots_app/modules/heroes/widgets/level_up_points_chip.dart';
import 'package:roots_app/modules/heroes/widgets/attribute_counter_row.dart';
import 'package:roots_app/modules/heroes/widgets/level_up_preview_panel.dart';

class HeroStatsTab extends StatelessWidget {
  final HeroModel hero;

  const HeroStatsTab({super.key, required this.hero});

  String _formatTime(int seconds) {
    if (seconds < 60) return '$seconds s';
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;
    return remaining == 0 ? '$minutes m' : '$minutes m $remaining s';
  }

  String _formatMsToMinutesSeconds(int ms) {
    final totalSeconds = ms ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    if (minutes == 0) return '$seconds s';
    if (seconds == 0) return '$minutes m';
    return '$minutes m $seconds s';
  }

  @override
  Widget build(BuildContext context) {
    // Live-reactive tokens
    context.watch<StyleManager>();
    final glass = kStyle.glass;
    final text = kStyle.textOnGlass;
    final buttons = kStyle.buttons;
    final cardPad = kStyle.card.padding;

    final isMobile = MediaQuery.of(context).size.width < 1024;

    // Provide a local LevelUpController for this tab.
    // (We can lift this provider to HeroDetailsScreen later.)
    return ChangeNotifierProvider<LevelUpController>(
      create: (_) => LevelUpController(hero: hero),
      child: Consumer<LevelUpController>(
        builder: (context, controller, _) {
          // Keep controller in sync if parent passes a fresher hero
          if (controller.hero.id != hero.id ||
              controller.hero.updatedAt != hero.updatedAt) {
            controller.updateHero(hero);
          }

          return StreamBuilder<DocumentSnapshot>(
            stream: hero.groupId != null
                ? FirebaseFirestore.instance
                .collection('heroGroups')
                .doc(hero.groupId)
                .snapshots()
                : null,
            builder: (context, snapshot) {
              HeroGroupModel? group;
              String locationText = 'Loading...';

              if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
                group = HeroGroupModel.fromFirestore(
                  snapshot.data!.id,
                  snapshot.data!.data()! as Map<String, dynamic>,
                );
                final inVillage = group.insideVillage == true;
                locationText = "(${group.tileX}, ${group.tileY})${inVillage ? ' • In Village' : ''}";
              }

              final stats = hero.stats ?? const {};
              final strength = (stats['strength'] ?? 0);
              final dexterity = (stats['dexterity'] ?? 0);
              final intelligence = (stats['intelligence'] ?? 0);
              final constitution = (stats['constitution'] ?? 0);

              final alloc = controller.allocation;
              final aSTR = alloc['strength'] ?? 0;
              final aDEX = alloc['dexterity'] ?? 0;
              final aINT = alloc['intelligence'] ?? 0;
              final aCON = alloc['constitution'] ?? 0;

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(cardPad.left, cardPad.top, cardPad.right, cardPad.bottom),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 📍 Location box (coords left, Found Village right)
                    TokenPanel(
                      glass: glass,
                      text: text,
                      padding: EdgeInsets.symmetric(
                        horizontal: cardPad.horizontal / 2,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              "📍 $locationText",
                              style: TextStyle(
                                color: text.secondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (group != null)
                            FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance.doc('mapTiles/${group.tileKey}').get(),
                              builder: (context, mapSnap) {
                                final hasVillage = mapSnap.data?.data() != null &&
                                    (mapSnap.data!.data() as Map)['villageId'] != null;

                                final isEligible = hero.state == 'idle' &&
                                    !group!.insideVillage &&
                                    !hasVillage;

                                return Tooltip(
                                  message: isEligible
                                      ? 'Found a new village on this tile.'
                                      : 'Cannot found village: hero must be idle, not in a village, and tile must be empty.',
                                  child: TokenIconButton(
                                    glass: glass,
                                    text: text,
                                    buttons: buttons,
                                    variant: TokenButtonVariant.primary,
                                    icon: const Icon(Icons.flag),
                                    label: const Text("Found Village"),
                                    onPressed: isEligible
                                        ? () {
                                      Provider.of<MainContentController>(context, listen: false)
                                          .setCustomContent(FoundVillageScreen(group: group!));
                                    }
                                        : null,
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Movement summary (your existing widget)
                    HeroMovementCard(hero: hero, group: group, isMobile: isMobile),
                    const SizedBox(height: 12),

                    const SizedBox(height: 16),

                    // 🧙 Hero Info
                    _infoPanel(
                      title: "🧙 Hero Info",
                      glass: glass,
                      text: text,
                      padding: cardPad,
                      children: [
                        _statRow("Name", hero.heroName, text),
                        _statRow("Race", hero.race, text),
                        _statRow("Level", hero.level.toString(), text),
                        _statRow("State", _formatHeroState(hero.state), text,
                            color: _stateColor(hero.state)),
                      ],
                    ),

                    // ⚔️ Combat Stats
                    _infoPanel(
                      title: "⚔️ Combat Stats",
                      glass: glass,
                      text: text,
                      padding: cardPad,
                      children: [
                        _statRow("Experience", hero.experience.toString(), text),
                        _statRow("Magic Resistance", hero.magicResistance.toString(), text),
                        _barRow("HP", hero.hp, hero.hpMax,
                            barColor: Theme.of(context).colorScheme.error, text: text, glass: glass),
                        if (hero.type != 'companion')
                          _barRow("Mana", hero.mana, hero.manaMax,
                              barColor: Theme.of(context).colorScheme.primary, text: text, glass: glass),
                      ],
                    ),

                    // 📊 Attributes (with inline level-up controls)
                    _infoPanel(
                      title: "📊 Attributes",
                      glass: glass,
                      text: text,
                      padding: cardPad,
                      children: [
                        // Chip row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Allocate points',
                              style: TextStyle(
                                color: text.secondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            LevelUpPointsChip(
                              unspentPoints: controller.unspentPoints,
                              pendingLevelUp: controller.pendingLevelUp && !controller.acknowledgedLocally,
                              isBusy: controller.isBusy,
                              onTap: () {
                                // no-op for now; chip is informational and clickable if you later want to scroll to preview
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Attribute rows with +/- and live delta
                        AttributeCounterRow(
                          label: 'Strength',
                          baseValue: strength,
                          allocatedDelta: aSTR,
                          canIncrement: controller.pointsLeft > 0 && !controller.isSpendLocked,
                          canDecrement: aSTR > 0 && !controller.isSpendLocked,
                          busy: controller.isBusy,
                          tooltip: 'Increases damage and carry capacity.',
                          onIncrement: () => controller.increment('strength'),
                          onDecrement: () => controller.decrement('strength'),
                        ),
                        AttributeCounterRow(
                          label: 'Dexterity',
                          baseValue: dexterity,
                          allocatedDelta: aDEX,
                          canIncrement: controller.pointsLeft > 0 && !controller.isSpendLocked,
                          canDecrement: aDEX > 0 && !controller.isSpendLocked,
                          busy: controller.isBusy,
                          tooltip: 'Improves hit chance and attack speed.',
                          onIncrement: () => controller.increment('dexterity'),
                          onDecrement: () => controller.decrement('dexterity'),
                        ),
                        AttributeCounterRow(
                          label: 'Intelligence',
                          baseValue: intelligence,
                          allocatedDelta: aINT,
                          canIncrement: controller.pointsLeft > 0 && !controller.isSpendLocked,
                          canDecrement: aINT > 0 && !controller.isSpendLocked,
                          busy: controller.isBusy,
                          tooltip: 'Boosts mana, regen, and defense.',
                          onIncrement: () => controller.increment('intelligence'),
                          onDecrement: () => controller.decrement('intelligence'),
                        ),
                        AttributeCounterRow(
                          label: 'Constitution',
                          baseValue: constitution,
                          allocatedDelta: aCON,
                          canIncrement: controller.pointsLeft > 0 && !controller.isSpendLocked,
                          canDecrement: aCON > 0 && !controller.isSpendLocked,
                          busy: controller.isBusy,
                          tooltip: 'Raises HP, regen, and defense.',
                          onIncrement: () => controller.increment('constitution'),
                          onDecrement: () => controller.decrement('constitution'),
                        ),

                        // Live preview + actions (Acknowledge / Reset / Confirm)
                        if (controller.pendingLevelUp || controller.allocatedTotal > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: LevelUpPreviewPanel(controller: controller),
                          ),
                      ],
                    ),

                    // ⚙️ Combat Mechanics
                    _infoPanel(
                      title: "⚙️ Combat Mechanics",
                      glass: glass,
                      text: text,
                      padding: cardPad,
                      children: [
                        _statRow("Attack Min", hero.combat['attackMin'].toString(), text),
                        _statRow("Attack Max", hero.combat['attackMax'].toString(), text),
                        _statRow("Armor", hero.combat['defense'].toString(), text),
                        _statRowWithInfo("Attack Rating (at)", hero.combat['at'].toString(), text,
                            tooltip: "Hit chance."),
                        _statRowWithInfo("Defense Rating (def)", hero.combat['def'].toString(), text,
                            tooltip: "Avoid hits."),
                        _statRowWithInfo("Combat Level", hero.combatLevel.toString(), text,
                            tooltip: "Matchmaking power."),
                        _statRowWithInfo("Regen per Tick", hero.combat['regenPerTick'].toString(), text,
                            tooltip: "HP per 10s."),
                        _statRowWithInfo("Attack Speed", _formatMsToMinutesSeconds(hero.combat['attackSpeedMs']), text,
                            tooltip: "Combat pacing."),
                        _statRowWithInfo("Estimated DPS", _calculateDPS(hero.combat), text,
                            tooltip: "(min+max)/2 / speed"),
                      ],
                    ),

                    // 🌿 Survival & Regen
                    _infoPanel(
                      title: "🌿 Survival & Regen",
                      glass: glass,
                      text: text,
                      padding: cardPad,
                      children: [
                        _statRow("HP Regen", _formatTime(hero.hpRegen), text),
                        _statRow("Mana Regen", _formatTime(hero.manaRegen), text),
                        _statRow("Food consumption every", _formatTime(hero.foodDuration), text),
                        HeroWeightBar(
                          currentWeight: hero.currentWeight.toDouble(),
                          carryCapacity: hero.carryCapacity.toDouble(),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ==== tokenized building blocks ====

  Widget _infoPanel({
    required String title,
    required GlassTokens glass,
    required TextOnGlassTokens text,
    required EdgeInsets padding,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TokenPanel(
        glass: glass,
        text: text,
        padding: EdgeInsets.fromLTRB(
          padding.left,
          14,
          padding.right,
          14,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: text.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _statRow(String label, String value, TextOnGlassTokens text, {Color? color}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: text.secondary)),
        Text(value, style: TextStyle(color: color ?? text.primary)),
      ],
    ),
  );

  Widget _statRowWithInfo(String label, String value, TextOnGlassTokens text, {String? tooltip}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(color: text.secondary)),
            if (tooltip != null)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Tooltip(
                  message: tooltip,
                  child: Icon(Icons.info_outline, size: 14, color: text.subtle),
                ),
              ),
          ],
        ),
        Text(value, style: TextStyle(color: text.primary)),
      ],
    ),
  );

  Widget _barRow(
      String label,
      int current,
      int max, {
        required Color barColor,
        required TextOnGlassTokens text,
        required GlassTokens glass,
      }) {
    final percent = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;
    final bg = glass.baseColor.withValues(alpha: glass.mode == SurfaceMode.solid ? 0.10 : 0.08);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: $current / $max", style: TextStyle(color: text.secondary)),
          const SizedBox(height: 4),
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 500),
            tween: Tween(begin: 0.0, end: percent),
            builder: (context, value, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor: bg,
                  color: barColor,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Color _stateColor(String state) {
    switch (state) {
      case 'idle':
        return Colors.green;
      case 'moving':
        return Colors.orange;
      case 'in_combat':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatHeroState(String state) {
    switch (state) {
      case 'idle':
        return '🟢 idle';
      case 'moving':
        return '🟡 moving';
      case 'in_combat':
        return '🔴 in combat';
      default:
        return '❔ unknown';
    }
  }

  String _calculateDPS(Map<String, dynamic> combat) {
    final min = (combat['attackMin'] ?? 0) as num;
    final max = (combat['attackMax'] ?? 0) as num;
    final speedMs = (combat['attackSpeedMs'] ?? 1000) as num;
    final avg = (min + max) / 2;
    final seconds = speedMs / 1000;
    if (seconds == 0) return '∞';
    final dps = avg / seconds;
    return dps.toStringAsFixed(2);
  }
}
