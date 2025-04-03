import 'package:flutter/material.dart';

class UpgradeButton extends StatelessWidget {
  final String buildingType;
  final int currentLevel;
  final VoidCallback? onUpgradeQueued;

  const UpgradeButton({
    super.key,
    required this.buildingType,
    required this.currentLevel,
    required this.onUpgradeQueued,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onUpgradeQueued != null;

    return ElevatedButton(
      onPressed: isEnabled ? onUpgradeQueued : null,
      style: ElevatedButton.styleFrom(
        elevation: isEnabled ? 2 : 0,
        backgroundColor: isEnabled ? Colors.blue : Colors.grey.shade300,
        foregroundColor: isEnabled ? Colors.white : Colors.grey.shade600,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
      child: const Text('Upgrade'),
    );
  }
}
