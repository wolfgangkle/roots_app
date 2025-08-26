import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 🔷 Tokens
import 'package:roots_app/theme/app_style_manager.dart';
import 'package:roots_app/theme/widgets/token_panels.dart';

class BrowseGuildsPlaceholder extends StatelessWidget {
  const BrowseGuildsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    // 🔄 Live-reactive tokens
    context.watch<StyleManager>();
    final glass   = kStyle.glass;
    final text    = kStyle.textOnGlass;
    final cardPad = kStyle.card.padding;

    return Padding(
      padding: EdgeInsets.fromLTRB(cardPad.left, 12, cardPad.right, cardPad.bottom),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: TokenPanel(
            glass: glass,
            text: text,
            padding: EdgeInsets.fromLTRB(cardPad.left, 16, cardPad.right, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.groups, size: 28, color: text.secondary),
                const SizedBox(height: 8),
                Text(
                  "Browse Guilds coming soon",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: text.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "For now, ask your friends for an invite 😉",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: text.secondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
