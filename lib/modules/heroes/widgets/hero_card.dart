import 'package:flutter/material.dart';
import 'package:roots_app/modules/heroes/models/hero_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class HeroCard extends StatelessWidget {
  final HeroModel hero;
  final VoidCallback? onTap;

  const HeroCard({required this.hero, this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    final percentHp =
        hero.hpMax > 0 ? (hero.hp / hero.hpMax).clamp(0.0, 1.0) : 0.0;
    final groupRef =
        FirebaseFirestore.instance.collection('heroGroups').doc(hero.groupId);

    return FutureBuilder<DocumentSnapshot>(
      future: groupRef.get(),
      builder: (context, snapshot) {
        String positionText = "";
        if (snapshot.hasData && snapshot.data?.data() != null) {
          final groupData = snapshot.data!.data() as Map<String, dynamic>;
          final tileX = groupData['tileX'];
          final tileY = groupData['tileY'];
          if (tileX != null && tileY != null) {
            positionText = "📍 $tileX / $tileY";
          }
        }

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Header row: Name + State + Position
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        hero.heroName,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatHeroState(hero.state),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: _stateColor(hero.state),
                            ),
                          ),
                          if (positionText.isNotEmpty)
                            Text(positionText,
                                style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),
                  Text("Level ${hero.level} • ${hero.race}",
                      style: Theme.of(context).textTheme.bodyMedium),

                  const SizedBox(height: 8),

                  /// HP bar
                  LinearProgressIndicator(
                    value: percentHp,
                    backgroundColor: Colors.grey.shade300,
                    color: Theme.of(context).colorScheme.error,
                    minHeight: 6,
                  ),
                  const SizedBox(height: 4),
                  Text("HP: ${hero.hp} / ${hero.hpMax}",
                      style: Theme.of(context).textTheme.bodySmall),

                  /// Mana bar
                  if (hero.type == 'mage') ...[
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: hero.manaMax > 0
                          ? (hero.mana / hero.manaMax).clamp(0.0, 1.0)
                          : 0.0,
                      backgroundColor: Colors.grey.shade300,
                      color: Theme.of(context).colorScheme.primary,
                      minHeight: 6,
                    ),
                    const SizedBox(height: 4),
                    Text("Mana: ${hero.mana} / ${hero.manaMax}",
                        style: Theme.of(context).textTheme.bodySmall),
                  ],

                  /// Countdown
                  if (hero.state == 'moving' && hero.arrivesAt != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: _LiveCountdown(arrivesAt: hero.arrivesAt!),
                    ),
                ],
              ),
            ),
          ),
        );
      },
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
    _timer =
        Timer.periodic(const Duration(seconds: 1), (_) => _updateRemaining());
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

    return Text(
      "🕒 $mm:$ss until arrival",
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}
