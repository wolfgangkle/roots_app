// lib/modules/chat/chat_panel.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:roots_app/modules/chat/chat_service.dart';
import 'package:roots_app/modules/chat/chat_message_tile.dart';
import 'package:roots_app/modules/chat/chat_input_field.dart';
import 'package:roots_app/modules/chat/chat_message_model.dart';

import 'package:roots_app/theme/app_style_manager.dart';
// Removed: token_panels import — no background boxes anymore

class ChatPanel extends StatelessWidget {
  final String currentUserName;

  const ChatPanel({super.key, required this.currentUserName});

  @override
  Widget build(BuildContext context) {
    final style = context.watch<StyleManager>().currentStyle;
    final text = style.textOnGlass;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header (transparent, no panel)
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Text(
            '🌍 Global Chat',
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
              stream: ChatService.getMessageStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data ?? [];

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  reverse: true, // newest at bottom visually
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[messages.length - index - 1];
                    return ChatMessageTile(message: message);
                  },
                );
              },
            ),
          ),
        ),

        // Input (kept tokenized: feels good as a grounded control bar)
        ChatInputField(sender: currentUserName),
      ],
    );
  }
}
