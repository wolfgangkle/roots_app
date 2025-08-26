import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:roots_app/modules/profile/models/user_profile_model.dart';
import 'package:roots_app/modules/profile/views/guild_profile_screen.dart';

// 🔷 Tokens
import 'package:roots_app/theme/app_style_manager.dart';
import 'package:roots_app/theme/widgets/token_panels.dart';

class GuildScreen extends StatelessWidget {
  const GuildScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 🔄 Live-reactive tokens
    context.watch<StyleManager>();
    final glass   = kStyle.glass;
    final text    = kStyle.textOnGlass;
    final cardPad = kStyle.card.padding;

    final profile = context.watch<UserProfileModel>();
    final guildId = profile.guildId;

    if (guildId != null) {
      return GuildProfileScreen(guildId: guildId);
    }

    // Empty state if not in a guild
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text("Guild", style: TextStyle(color: text.primary)),
        iconTheme: IconThemeData(color: text.primary),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, kToolbarHeight + 16, 16, 16),
        children: [
          TokenPanel(
            glass: glass,
            text: text,
            padding: EdgeInsets.fromLTRB(cardPad.left, 14, cardPad.right, 14),
            child: Row(
              children: [
                Icon(Icons.group_off, color: text.secondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "You are not in a guild.",
                    style: TextStyle(color: text.secondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
