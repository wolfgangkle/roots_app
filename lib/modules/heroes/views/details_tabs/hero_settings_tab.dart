import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 🔷 Tokens
import 'package:roots_app/theme/app_style_manager.dart';
import 'package:roots_app/theme/widgets/token_panels.dart';

class HeroSettingsTab extends StatelessWidget {
  const HeroSettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Live-reactive tokens
    context.watch<StyleManager>();
    final glass = kStyle.glass;
    final text = kStyle.textOnGlass;
    final pad = kStyle.card.padding;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(pad.left, pad.top, pad.right, pad.bottom),
      child: TokenPanel(
        glass: glass,
        text: text,
        padding: EdgeInsets.fromLTRB(pad.left, 16, pad.right, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "⚙️ Hero Settings",
              style: TextStyle(
                color: text.primary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "This tab is coming soon. You’ll manage hero name, portrait, and more here.",
              style: TextStyle(color: text.secondary),
            ),
          ],
        ),
      ),
    );
  }
}
