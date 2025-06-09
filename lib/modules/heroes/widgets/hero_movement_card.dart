import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:roots_app/modules/heroes/models/hero_model.dart';
import 'package:roots_app/modules/heroes/models/hero_group_model.dart';
import 'package:roots_app/modules/heroes/views/hero_group_movement_screen.dart';
import 'package:roots_app/screens/controllers/main_content_controller.dart';
import 'package:roots_app/screens/helpers/responsive_push.dart';

class HeroMovementCard extends StatefulWidget {
  final HeroModel hero;
  final HeroGroupModel? group;
  final bool isMobile;

  const HeroMovementCard({
    super.key,
    required this.hero,
    required this.group,
    required this.isMobile,
  });

  @override
  State<HeroMovementCard> createState() => _HeroMovementCardState();
}

class _HeroMovementCardState extends State<HeroMovementCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimerIfNeeded();
  }

  @override
  void didUpdateWidget(covariant HeroMovementCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _startTimerIfNeeded();
  }

  void _startTimerIfNeeded() {
    _timer?.cancel();
    final arrivesAt = widget.group?.arrivesAt;
    if (arrivesAt != null && arrivesAt.isAfter(DateTime.now())) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
        if (arrivesAt.isBefore(DateTime.now())) {
          _timer?.cancel();
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatArrival(Duration duration) {
    final seconds = duration.inSeconds;
    if (seconds < 60) return '$seconds s';
    final minutes = duration.inMinutes;
    final remaining = seconds % 60;
    return '$minutes m ${remaining}s';
  }

  String _formatTime(int seconds) {
    if (seconds < 60) return '$seconds s';
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;
    return remaining == 0 ? '$minutes m' : '$minutes m $remaining s';
  }

  @override
  Widget build(BuildContext context) {
    final hero = widget.hero;
    final group = widget.group;
    final isMobile = widget.isMobile;
    final now = DateTime.now();

    final isMoving = hero.state == 'moving' && hero.arrivesAt != null;
    final waypoints = group?.movementQueue ?? [];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("🧭 Movement",
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            if (group != null) ...[
              const Text("Current Move:"),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Current Tile:"),
                  Text("(${group.tileX}, ${group.tileY})"),
                ],
              ),
              if (waypoints.isNotEmpty) ...[
                if (group.arrivesAt != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Arrives in:"),
                      Text(group.arrivesAt!.isAfter(now)
                          ? _formatArrival(group.arrivesAt!.difference(now))
                          : 'Arrived'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Arrives at:"),
                      Text(DateFormat('HH:mm:ss').format(group.arrivesAt!)),
                    ],
                  ),
                ] else ...[
                  const Text("No arrival time set."),
                ],
              ],

              const SizedBox(height: 12),
            ],

            if (waypoints.length > 1) ...[
              const Text("Set Waypoints:"),
              const SizedBox(height: 8),
              ...waypoints.sublist(1).asMap().entries.map((entry) {
                final index = entry.key + 2; // skipping the first
                final step = entry.value;
                final action = step['action'];
                String label;

                if (action == 'walk') {
                  label = "(${step['x']}, ${step['y']})";
                } else if (action == 'enterVillage') {
                  label = "Enter Village";
                } else if (action == 'exitVillage') {
                  label = "Exit Village";
                } else {
                  label = "Action: $action";
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text("Waypoint $index → $label"),
                );
              }),
              const SizedBox(height: 12),
            ],

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Movement Speed:"),
                Text(_formatTime(hero.movementSpeed)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Text("Max Waypoints"),
                    SizedBox(width: 4),
                    Tooltip(
                      message:
                      "Max path steps your hero can queue. Scales with INT later.",
                      child: Icon(Icons.info_outline, size: 14, color: Colors.grey),
                    ),
                  ],
                ),
                Text(hero.maxWaypoints.toString()),
              ],
            ),

            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.edit_location_alt),
                label: Text(hero.state == 'idle' ? 'Move Hero' : 'Edit Movement'),
                onPressed: group == null
                    ? null
                    : () {
                  if (isMobile) {
                    pushResponsiveScreen(
                      context,
                      HeroGroupMovementScreen(hero: hero, group: group),
                    );
                  } else {
                    final controller = Provider.of<MainContentController>(
                        context,
                        listen: false);
                    controller.setCustomContent(
                      HeroGroupMovementScreen(hero: hero, group: group),
                    );
                  }
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
