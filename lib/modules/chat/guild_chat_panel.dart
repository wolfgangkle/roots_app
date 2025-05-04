import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roots_app/modules/chat/chat_service.dart';
import 'package:roots_app/modules/chat/chat_message_model.dart';
import 'package:roots_app/modules/chat/guild_chat_message_tile.dart';
import 'package:roots_app/profile/models/user_profile_model.dart';
import 'package:roots_app/modules/chat/guild_chat_input_field.dart';

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

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            '🏰 Guild Chat',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<ChatMessage>>(
            stream: ChatService.getGuildMessageStream(guildId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final messages = snapshot.data ?? [];

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8),
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
        GuildChatInputField(guildId: guildId, sender: heroName),
      ],
    );
  }
}
