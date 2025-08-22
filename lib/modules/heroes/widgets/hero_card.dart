import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart'; // 👈 watch StyleManager
import 'package:roots_app/modules/heroes/models/hero_model.dart';
import 'package:roots_app/widgets/mini_glass_card.dart';
import 'package:roots_app/theme/tokens.dart';
import 'package:roots_app/theme/app_style_manager.dart';

// Getters so tokens update live with theme
GlassTokens get glass => kStyle.glass;
TextOnGlassTokens get textOnGlass => kStyle.textOnGlass;

class HeroCard extends StatelessWidget {
  final HeroModel hero;
  final VoidCallback? onTap;

  const HeroCard({required this.hero, this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    // 👇 Rebuild when StyleManager notifies (theme switch)
    context.watch<StyleManager>();

    final percentHp = hero.hpMax > 0 ? (hero.hp / hero.hpMax).clamp(0.0, 1.0) : 0.0;
    final groupRef = FirebaseFirestore.instance.collection('heroGroups').doc(hero.groupId);

    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
      color: textOnGlass.primary.withValues(alpha: 0.95),
    );
    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: textOnGlass.secondary.withValues(alpha: 0.78),
    );
    final subtleStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: textOnGlass.subtle.withValues(alpha: 0.64),
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return FutureBuilder<DocumentSnapshot>(
      future: groupRef.get(),
      builder: (context, snapshot) {
        String positionText = "";
        if (snapshot.hasData && snapshot.data?.data() != null) {
          final groupData = snapshot.data!.data() as Map<String, dynamic>;
          final tileX = groupData['tileX'];
          final tileY = groupData['tileY'];
          if (tileX != null && tileY != null) positionText = "📍 $tileX / $tileY";
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: MiniGlassCard(
            onTap: onTap,
            opacity: glass.opacity,
            sigma: glass.mode == SurfaceMode.glass ? glass.blurSigma : 0.0, // respect solid mode
            cornerGap: glass.cornerGap,
            strokeOpacity: glass.strokeOpacity,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(hero.heroName, style: titleStyle),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _StatePill(state: hero.state),
                          if (positionText.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(positionText, style: subtleStyle),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text("Level ${hero.level} • ${hero.race}", style: bodyStyle),

                  const SizedBox(height: 10),

                  // HP bar
                  _TokenProgressBar(
                    value: percentHp,
                    background: textOnGlass.subtle.withValues(alpha: 0.18),
                    barColor: Theme.of(context).colorScheme.error,
                    height: 6,
                  ),
                  const SizedBox(height: 4),
                  Text("HP: ${hero.hp} / ${hero.hpMax}", style: subtleStyle),

                  // Mana bar
                  if (hero.type == 'mage') ...[
                    const SizedBox(height: 8),
                    _TokenProgressBar(
                      value: hero.manaMax > 0 ? (hero.mana / hero.manaMax).clamp(0.0, 1.0) : 0.0,
                      background: textOnGlass.subtle.withValues(alpha: 0.18),
                      barColor: Theme.of(context).colorScheme.primary,
                      height: 6,
                    ),
                    const SizedBox(height: 4),
                    Text("Mana: ${hero.mana} / ${hero.manaMax}", style: subtleStyle),
                  ],

                  // Countdown
                  if (hero.state == 'moving' && hero.arrivesAt != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _LiveCountdown(arrivesAt: hero.arrivesAt!, textStyle: subtleStyle),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Small token-styled progress bar
class _TokenProgressBar extends StatelessWidget {
  final double value;
  final double height;
  final Color barColor;
  final Color background;

  const _TokenProgressBar({
    required this.value,
    required this.barColor,
    required this.background,
    this.height = 6,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Stack(
        children: [
          Container(height: height, width: double.infinity, color: background),
          FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value.isNaN ? 0.0 : value.clamp(0.0, 1.0),
            child: Container(height: height, color: barColor.withValues(alpha: 0.9)),
          ),
        ],
      ),
    );
  }
}

/// Compact state pill using token text colors
class _StatePill extends StatelessWidget {
  final String state;
  const _StatePill({required this.state});

  @override
  Widget build(BuildContext context) {
    final t = textOnGlass;
    final label = switch (state) {
      'idle' => '🟢 idle',
      'moving' => '🟡 moving',
      'in_combat' => '🔴 in combat',
      _ => '❔ unknown',
    };

    final Color fg = t.primary.withValues(alpha: 0.92);
    final Color bg = t.subtle.withValues(alpha: 0.10);
    final Color border = t.subtle.withValues(alpha: 0.18);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border, width: 1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: fg,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _LiveCountdown extends StatefulWidget {
  final DateTime arrivesAt;
  final TextStyle? textStyle;
  const _LiveCountdown({required this.arrivesAt, this.textStyle});

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
    return Text("🕒 $mm:$ss until arrival", style: widget.textStyle);
  }
}
