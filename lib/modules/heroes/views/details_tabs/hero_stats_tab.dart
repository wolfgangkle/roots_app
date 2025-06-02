import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:roots_app/modules/heroes/models/hero_model.dart';
import 'package:roots_app/modules/heroes/models/hero_group_model.dart';
import 'package:roots_app/modules/heroes/widgets/hero_movement_card.dart';
import 'package:roots_app/screens/controllers/main_content_controller.dart';
import 'package:roots_app/screens/helpers/responsive_push.dart';
import 'package:roots_app/modules/heroes/views/found_village_screen.dart';
import 'package:roots_app/modules/heroes/widgets/hero_weight_bar.dart';

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
    final isMobile = MediaQuery.of(context).size.width < 1024;

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

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("📍 $locationText", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              HeroMovementCard(hero: hero, group: group, isMobile: isMobile),
              const SizedBox(height: 12),
              _infoCard(context, "🧙 Hero Info", [
                _statRow("Name", hero.heroName),
                _statRow("Race", hero.race),
                _statRow("Level", hero.level.toString()),
                _statRow("State", _formatHeroState(hero.state), color: _stateColor(hero.state)),
              ]),
              _infoCard(context, "⚔️ Combat Stats", [
                _statRow("Experience", hero.experience.toString()),
                _statRow("Magic Resistance", hero.magicResistance.toString()),
                _barRow(context, "HP", hero.hp, hero.hpMax, color: Theme.of(context).colorScheme.error),
                if (hero.type != 'companion')
                  _barRow(context, "Mana", hero.mana, hero.manaMax, color: Theme.of(context).colorScheme.primary),
              ]),
              _infoCard(context, "📊 Attributes", [
                _attributeBar(context, "Strength", hero.stats['strength'] ?? 0),
                _attributeBar(context, "Dexterity", hero.stats['dexterity'] ?? 0),
                _attributeBar(context, "Intelligence", hero.stats['intelligence'] ?? 0),
                _attributeBar(context, "Constitution", hero.stats['constitution'] ?? 0),
              ]),
              _infoCard(context, "🗌 Movement & Waypoints", [
                _statRow("Movement Speed", _formatTime(hero.movementSpeed)),
                _statRowWithInfo("Max Waypoints", hero.maxWaypoints.toString(), tooltip: "Scales with INT later."),
              ]),
              _infoCard(context, "⚙️ Combat Mechanics", [
                _statRow("Attack Min", hero.combat['attackMin'].toString()),
                _statRow("Attack Max", hero.combat['attackMax'].toString()),
                _statRow("Armor", hero.combat['defense'].toString()),
                _statRowWithInfo("Attack Rating (at)", hero.combat['at'].toString(), tooltip: "Hit chance."),
                _statRowWithInfo("Defense Rating (def)", hero.combat['def'].toString(), tooltip: "Avoid hits."),
                _statRowWithInfo("Combat Level", hero.combatLevel.toString(), tooltip: "Matchmaking power."),
                _statRowWithInfo("Regen per Tick", hero.combat['regenPerTick'].toString(), tooltip: "HP per 10s."),
                _statRowWithInfo("Attack Speed", _formatMsToMinutesSeconds(hero.combat['attackSpeedMs']), tooltip: "Combat pacing."),
                _statRowWithInfo("Estimated DPS", _calculateDPS(hero.combat), tooltip: "(min+max)/2 / speed"),
              ]),
              _infoCard(context, "🌿 Survival & Regen", [
                _statRow("HP Regen", _formatTime(hero.hpRegen)),
                _statRow("Mana Regen", _formatTime(hero.manaRegen)),
                _statRow("Food consumption every", _formatTime(hero.foodDuration)),
                HeroWeightBar(currentWeight: hero.currentWeight.toDouble(), carryCapacity: hero.carryCapacity.toDouble()),
              ]),
            ],
          ),
        );
      },
    );
  }

  Widget _infoCard(BuildContext context, String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _statRow(String label, String value, {Color? color}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(value, style: TextStyle(color: color)),
      ],
    ),
  );

  Widget _statRowWithInfo(String label, String value, {String? tooltip}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(label),
            if (tooltip != null)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Tooltip(
                  message: tooltip,
                  child: const Icon(Icons.info_outline, size: 14, color: Colors.grey),
                ),
              ),
          ],
        ),
        Text(value),
      ],
    ),
  );

  Widget _barRow(BuildContext context, String label, int current, int max, {required Color color}) {
    final percent = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: $current / $max"),
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 500),
            tween: Tween(begin: 0.0, end: percent),
            builder: (context, value, _) {
              return LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: Colors.grey.shade300,
                color: color,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _attributeBar(BuildContext context, String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 140, child: Text(label)),
          Expanded(
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 600),
              tween: Tween(begin: 0.0, end: value.toDouble()),
              builder: (context, val, _) {
                return LinearProgressIndicator(
                  value: val / 500,
                  minHeight: 10,
                  backgroundColor: Colors.grey.shade200,
                  color: Theme.of(context).colorScheme.secondary,
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          Text(value.toString()),
        ],
      ),
    );
  }

  Color _stateColor(String state) {
    switch (state) {
      case 'idle': return Colors.green;
      case 'moving': return Colors.orange;
      case 'in_combat': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _formatHeroState(String state) {
    switch (state) {
      case 'idle': return '🟢 idle';
      case 'moving': return '🟡 moving';
      case 'in_combat': return '🔴 in combat';
      default: return '❔ unknown';
    }
  }

  String _calculateDPS(Map<String, dynamic> combat) {
    final min = combat['attackMin'] ?? 0;
    final max = combat['attackMax'] ?? 0;
    final speedMs = combat['attackSpeedMs'] ?? 1000;
    final avg = (min + max) / 2;
    final seconds = speedMs / 1000;
    if (seconds == 0) return '∞';
    final dps = avg / seconds;
    return dps.toStringAsFixed(2);
  }
}
