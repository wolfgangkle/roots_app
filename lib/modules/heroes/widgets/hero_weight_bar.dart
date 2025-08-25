import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 🔷 Tokens
import 'package:roots_app/theme/app_style_manager.dart';
import 'package:roots_app/theme/tokens.dart';

class HeroWeightBar extends StatelessWidget {
  final num currentWeight;
  final num carryCapacity;

  const HeroWeightBar({
    super.key,
    required this.currentWeight,
    required this.carryCapacity,
  });

  @override
  Widget build(BuildContext context) {
    // Live-reactive tokens
    context.watch<StyleManager>();
    final glass = kStyle.glass;
    final text = kStyle.textOnGlass;

    final safeCapacity = carryCapacity <= 0 ? 1 : carryCapacity;
    final rawPercent = currentWeight / safeCapacity;
    final percent = rawPercent.clamp(0.0, 1.0).toDouble();

    // Glassy background for the track
    final bg = glass.baseColor.withValues(
      alpha: glass.mode == SurfaceMode.solid ? 0.10 : 0.08,
    );

    // Threshold-based bar color
    Color barColor() {
      if (rawPercent >= 0.9) return Colors.red;
      if (rawPercent >= 0.5) return Colors.orange;
      return Colors.green;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          "⚖️ Carried Weight: ${currentWeight.toStringAsFixed(2)} / ${safeCapacity.toStringAsFixed(2)}",
          style: TextStyle(
            color: text.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        // Animated progress with rounded corners and glass track
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
          tween: Tween(begin: 0, end: percent),
          builder: (context, value, _) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: bg,
                color: barColor(),
              ),
            );
          },
        ),
        // Optional helper text when overweight
        if (rawPercent > 1.0) ...[
          const SizedBox(height: 6),
          Text(
            "Over capacity! Drop items before moving.",
            style: TextStyle(
              color: Colors.red.withValues(alpha: 0.9),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
