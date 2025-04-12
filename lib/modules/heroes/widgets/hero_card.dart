import 'package:flutter/material.dart';
import 'package:roots_app/modules/heroes/models/hero_model.dart';
import 'dart:async';

class HeroCard extends StatelessWidget {
  final HeroModel hero;
  final VoidCallback? onTap;

  const HeroCard({required this.hero, this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    final percentHp = hero.hpMax > 0 ? (hero.hp / hero.hpMax).clamp(0.0, 1.0) : 0.0;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              hero.heroName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              _formatHeroState(hero.state),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _stateColor(hero.state),
                fontSize: 12,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Level ${hero.level} • ${hero.race}"),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: percentHp,
              backgroundColor: Colors.grey.shade300,
              color: Colors.red.shade400,
              minHeight: 6,
            ),
            const SizedBox(height: 2),
            Text("HP: ${hero.hp} / ${hero.hpMax}", style: const TextStyle(fontSize: 12)),

            if (hero.state == 'moving' && hero.arrivesAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: _LiveCountdown(arrivesAt: hero.arrivesAt!),
              ),
          ],
        ),
      ),
    );
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
}

class _LiveCountdown extends StatefulWidget {
  final DateTime arrivesAt;
  const _LiveCountdown({required this.arrivesAt});

  @override
  State<_LiveCountdown> createState() => _LiveCountdownState();
}

class _LiveCountdownState extends State<_LiveCountdown> {
  late Timer _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateRemaining());
  }

  void _updateRemaining() {
    final now = DateTime.now();
    final diff = widget.arrivesAt.difference(now);
    setState(() {
      _remaining = diff.isNegative ? Duration.zero : diff;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mm = _remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = _remaining.inSeconds.remainder(60).toString().padLeft(2, '0');

    return Text("🕒 $mm:$ss until arrival", style: const TextStyle(fontSize: 12));
  }
}
