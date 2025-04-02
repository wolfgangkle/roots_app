import 'package:flutter/material.dart';

class HeroPanel extends StatelessWidget {
  const HeroPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: const [
        Text('🧙‍♂️ Main Hero: Darik'),
        SizedBox(height: 12),
        Text('HP: 100'),
        Text('Mana: 50'),
        Divider(),
        Text('🧝 Companions:'),
        Text('• Marla (Lv. 1)'),
        Text('• Niko (Lv. 1)'),
        // ... add more mock heroes
      ],
    );
  }
}
