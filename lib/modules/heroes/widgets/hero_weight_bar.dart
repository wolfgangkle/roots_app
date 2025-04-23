import 'package:flutter/material.dart';

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
    final percent = (currentWeight / carryCapacity).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "⚖️ Carried Weight: ${currentWeight.toStringAsFixed(2)} / ${carryCapacity.toStringAsFixed(2)}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percent.toDouble(),
          minHeight: 8,
          backgroundColor: Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation<Color>(
            percent < 0.5
                ? Colors.green
                : percent < 0.9
                ? Colors.orange
                : Colors.red,
          ),
        ),
      ],
    );
  }
}

