import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:roots_app/modules/heroes/models/hero_model.dart';
import 'package:roots_app/modules/heroes/widgets/hero_weight_bar.dart';
import 'package:roots_app/modules/heroes/views/found_village_screen.dart';
import 'package:roots_app/modules/heroes/views/hero_movement_screen.dart';
import 'package:roots_app/screens/controllers/main_content_controller.dart';
import 'package:roots_app/screens/helpers/responsive_push.dart';

class HeroStatsTab extends StatefulWidget {
  final HeroModel hero;

  const HeroStatsTab({super.key, required this.hero});

  @override
  State<HeroStatsTab> createState() => _HeroStatsTabState();
}

class _HeroStatsTabState extends State<HeroStatsTab> {
  Map<String, dynamic>? _groupData;
  String? _villageName;
  bool _checkingTile = false;

  @override
  void initState() {
    super.initState();
    _loadGroupData();
  }

  Future<void> _loadGroupData() async {
    final groupId = widget.hero.groupId;
    if (groupId == null) return;

    final groupSnap = await FirebaseFirestore.instance
        .collection('heroGroups')
        .doc(groupId)
        .get();
    final data = groupSnap.data();
    if (data == null || !mounted) return;

    setState(() => _groupData = data);

    if (_groupData!['insideVillage'] == true) {
      final name =
      await _getVillageName(_groupData!['tileX'], _groupData!['tileY']);
      if (!mounted) return;
      setState(() => _villageName = name);
    }
  }

  Future<String?> _getVillageName(int x, int y) async {
    final query = await FirebaseFirestore.instance
        .collectionGroup('villages')
        .where('tileX', isEqualTo: x)
        .where('tileY', isEqualTo: y)
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) {
      return query.docs.first.data()['name'];
    }
    return null;
  }

  bool _canFoundVillage(HeroModel hero) {
    return true;
  }

  Future<void> _handleFoundVillage(HeroModel hero) async {
    setState(() => _checkingTile = true);

    final tileKey = '${hero.tileX}_${hero.tileY}';
    final snapshot = await FirebaseFirestore.instance
        .collectionGroup('villages')
        .where('tileKey', isEqualTo: tileKey)
        .limit(1)
        .get();

    final occupied = snapshot.docs.isNotEmpty;
    if (!mounted) return;
    setState(() => _checkingTile = false);

    if (occupied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A village already exists on this tile!')),
      );
      return;
    }

    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => FoundVillageScreen(hero: hero),
    ));
  }

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
    final hero = widget.hero;
    final isMobile = MediaQuery.of(context).size.width < 1024;
    final bool isMoving = hero.state == 'moving' && hero.arrivesAt != null;
    final bool hasQueuedWaypoints =
        hero.movementQueue != null && hero.movementQueue!.isNotEmpty;
    final bool hasMovement = isMoving || hasQueuedWaypoints;

    final String locationText;
    if (_groupData == null) {
      locationText = 'Loading...';
    } else {
      final x = _groupData!['tileX'];
      final y = _groupData!['tileY'];
      final inVillage = _groupData!['insideVillage'] == true;
      final villageLabel = inVillage
          ? _villageName != null
          ? " • In village ‘$_villageName’"
          : " • In Village"
          : "";
      locationText = "($x, $y)$villageLabel";
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoCard("🧙 Hero Info", [
            _statRow("Name", hero.heroName),
            _statRow("Race", hero.race),
            _statRow("Level", hero.level.toString()),
            _statRow("Location", "📍 $locationText"),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("State"),
                Text(
                  _formatHeroState(hero.state),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _stateColor(hero.state),
                  ),
                ),
              ],
            ),
          ]),
          if (hasMovement)
            _infoCard("🧭 Movement Status", [
              _statRow("Currently Moving", isMoving ? "Yes" : "No"),
              if (hasQueuedWaypoints)
                _statRow("Waypoints", "${hero.movementQueue?.length} queued"),
            ]),
          _infoCard("⚔️ Combat Stats", [
            _statRow("Experience", hero.experience.toString()),
            _statRow("Magic Resistance", hero.magicResistance.toString()),
            _barRow("HP", hero.hp, hero.hpMax,
                color: Theme.of(context).colorScheme.error),
            if (hero.type != 'companion')
              _barRow("Mana", hero.mana, hero.manaMax,
                  color: Theme.of(context).colorScheme.primary),
          ]),
          _infoCard("📊 Attributes", [
            _attributeBar("Strength", hero.stats['strength'] ?? 0),
            _attributeBar("Dexterity", hero.stats['dexterity'] ?? 0),
            _attributeBar("Intelligence", hero.stats['intelligence'] ?? 0),
            _attributeBar("Constitution", hero.stats['constitution'] ?? 0),
          ]),
          _infoCard("🗺️ Movement & Waypoints", [
            _statRow("Movement Speed", _formatTime(hero.movementSpeed)),
            _statRowWithInfo(
                "Max Waypoints", hero.maxWaypoints.toString(),
                tooltip:
                "Max path steps your hero can queue. Scales with INT later."),
          ]),
          _infoCard("⚙️ Combat Mechanics", [
            _statRow("Attack Min", hero.combat['attackMin'].toString()),
            _statRow("Attack Max", hero.combat['attackMax'].toString()),
            _statRow("Armor", hero.combat['defense'].toString()),
            _statRowWithInfo("Attack Rating (at)", hero.combat['at'].toString(),
                tooltip: "Used to calculate hit chance in combat."),
            _statRowWithInfo("Defense Rating (def)", hero.combat['def'].toString(),
                tooltip: "Used to resist attacks and avoid hits."),
            _statRowWithInfo("Combat Level", hero.combatLevel.toString(),
                tooltip: "Represents overall power. Used to match against enemies."),
            _statRowWithInfo(
                "Regen per Tick", hero.combat['regenPerTick'].toString(),
                tooltip: "HP regenerated per ~10s combat tick."),
            _statRowWithInfo("Attack Speed",
                _formatMsToMinutesSeconds(hero.combat['attackSpeedMs']),
                tooltip: "Time between each attack. Affects combat pacing."),
            _statRowWithInfo("Estimated DPS", _calculateDPS(hero.combat),
                tooltip: "Average DPS = ((min+max)/2) / attack speed"),
          ]),
          _infoCard("🌿 Survival & Regen", [
            _statRow("HP Regen", _formatTime(hero.hpRegen)),
            _statRow("Mana Regen", _formatTime(hero.manaRegen)),
            _statRow("Food consumption every", _formatTime(hero.foodDuration)),
            HeroWeightBar(
              currentWeight: hero.currentWeight.toDouble(),
              carryCapacity: hero.carryCapacity.toDouble(),
            ),
          ]),
          _debugCard(hero),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            icon: const Icon(Icons.edit_location_alt),
            label: Text(hero.state == 'idle' ? 'Move Hero' : 'Edit Movement'),
            onPressed: () {
              if (isMobile) {
                pushResponsiveScreen(context, HeroMovementScreen(hero: hero));
              } else {
                final controller =
                Provider.of<MainContentController>(context, listen: false);
                controller.setCustomContent(HeroMovementScreen(hero: hero));
              }
            },
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.location_city),
            label: const Text("Found New Village"),
            onPressed: _checkingTile || !_canFoundVillage(hero)
                ? null
                : () => _handleFoundVillage(hero),
          ),
          if (hero.type == 'companion') ...[
            const SizedBox(height: 8),
            Text(
              "💡 Companions can be converted into villages.\n"
                  "If no free slot is available, they will be sacrificed to make space.",
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.orange),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoCard(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _debugCard(HeroModel hero) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        title: Text("🛠️ Debug Info",
            style: Theme.of(context).textTheme.titleSmall),
        children: [
          _statRow("Group ID", hero.groupId ?? '—'),
          _statRow("Leader ID", hero.groupLeaderId ?? '—'),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(value),
          ],
        ),
      );

  Widget _statRowWithInfo(String label, String value, {String? tooltip}) {
    return Padding(
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
                    child: const Icon(Icons.info_outline,
                        size: 14, color: Colors.grey),
                  ),
                ),
            ],
          ),
          Text(value),
        ],
      ),
    );
  }

  Widget _barRow(String label, int current, int max, {required Color color}) {
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

  Widget _attributeBar(String label, int value) {
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
