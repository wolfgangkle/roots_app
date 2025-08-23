// lib/modules/chat/guild_chat_panel.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:roots_app/modules/chat/chat_service.dart';
import 'package:roots_app/modules/chat/chat_message_model.dart';
import 'package:roots_app/modules/chat/guild_chat_message_tile.dart';
import 'package:roots_app/modules/chat/guild_chat_input_field.dart';
import 'package:roots_app/modules/profile/models/user_profile_model.dart';

import 'package:roots_app/theme/app_style_manager.dart';

class GuildChatPanel extends StatelessWidget {
  const GuildChatPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = Provider.of<UserProfileModel>(context, listen: false);
    final heroName = profile.heroName;
    final guildId = profile.guildId;

    if (guildId == null) {
      return const Center(child: Text("You're not in a guild."));
    }

    final style = context.watch<StyleManager>().currentStyle;
    final text = style.textOnGlass;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header (transparent, no panel)
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Text(
            '🏰 Guild Chat',
            style: TextStyle(
              color: text.primary,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),

        // Messages list (transparent, no panel)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: StreamBuilder<List<ChatMessage>>(
              stream: ChatService.getGuildMessageStream(guildId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data ?? [];

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[messages.length - index - 1];
                    return GuildChatMessageTile(message: message);
                  },
                );
              },
            ),
          ),
        ),

        // Input bar (already tokenized inside its own widget)
        GuildChatInputField(guildId: guildId, sender: heroName),
      ],
    );
  }
}
