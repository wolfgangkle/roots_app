import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:roots_app/modules/heroes/models/hero_model.dart';
import 'package:roots_app/modules/heroes/models/hero_group_model.dart';
import 'package:roots_app/modules/heroes/views/hero_group_movement_screen.dart';
import 'package:roots_app/screens/controllers/main_content_controller.dart';
import 'package:roots_app/screens/helpers/responsive_push.dart';

// 🔷 Tokens
import 'package:roots_app/theme/app_style_manager.dart';
import 'package:roots_app/theme/widgets/token_panels.dart';
import 'package:roots_app/theme/widgets/token_buttons.dart';
import 'package:roots_app/theme/tokens.dart';

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
    // 🔁 tokens
    context.watch<StyleManager>();
    final glass = kStyle.glass;
    final text = kStyle.textOnGlass;
    final buttons = kStyle.buttons;
    final pad = kStyle.card.padding;

    final hero = widget.hero;
    final group = widget.group;
    final isMobile = widget.isMobile;
    final now = DateTime.now();

    final waypoints = group?.movementQueue ?? [];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TokenPanel(
        glass: glass,
        text: text,
        padding: EdgeInsets.fromLTRB(pad.left, 16, pad.right, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // header
            Row(
              children: [
                Text(
                  '🧭 Movement',
                  style: TextStyle(
                    color: text.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                TokenIconButton(
                  glass: glass,
                  text: text,
                  buttons: buttons,
                  variant: TokenButtonVariant.primary,
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
                      final controller =
                      Provider.of<MainContentController>(context, listen: false);
                      controller.setCustomContent(
                        HeroGroupMovementScreen(hero: hero, group: group),
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (group != null) ...[
              _kvRow('Current Tile:', '(${group.tileX}, ${group.tileY})', text),
              if (waypoints.isNotEmpty) ...[
                if (group.arrivesAt != null) ...[
                  const SizedBox(height: 4),
                  _kvRow(
                    'Arrives in:',
                    group.arrivesAt!.isAfter(now)
                        ? _formatArrival(group.arrivesAt!.difference(now))
                        : 'Arrived',
                    text,
                  ),
                  _kvRow('Arrives at:', DateFormat('HH:mm:ss').format(group.arrivesAt!), text),
                ] else
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('No arrival time set.', style: TextStyle(color: text.secondary)),
                  ),
              ],
              const SizedBox(height: 12),
            ],

            if (waypoints.length > 1) ...[
              Text('Set Waypoints:', style: TextStyle(color: text.primary, fontWeight: FontWeight.w600)),
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
                  child: Text("Waypoint $index → $label", style: TextStyle(color: text.secondary)),
                );
              }),
              const SizedBox(height: 12),
            ],

            _kvRow('Movement Speed:', _formatTime(hero.movementSpeed), text),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text('Max Waypoints', style: TextStyle(color: text.secondary)),
                    const SizedBox(width: 4),
                    Tooltip(
                      message: "Max path steps your hero can queue. Scales with INT later.",
                      child: Icon(Icons.info_outline, size: 14, color: text.subtle),
                    ),
                  ],
                ),
                Text(hero.maxWaypoints.toString(), style: TextStyle(color: text.primary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _kvRow(String k, String v, TextOnGlassTokens text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(k, style: TextStyle(color: text.secondary)),
        Text(v, style: TextStyle(color: text.primary)),
      ],
    );
  }
}
