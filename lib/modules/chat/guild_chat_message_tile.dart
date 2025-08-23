// lib/modules/chat/guild_chat_message_tile.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'chat_message_model.dart';

import 'package:roots_app/theme/app_style_manager.dart';
import 'package:roots_app/theme/widgets/token_panels.dart';

class GuildChatMessageTile extends StatelessWidget {
  final ChatMessage message;

  const GuildChatMessageTile({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final style = context.watch<StyleManager>().currentStyle;
    final text = style.textOnGlass;

    final date = DateFormat('dd.MM.yyyy').format(message.timestamp);
    final time = DateFormat.Hm().format(message.timestamp); // HH:mm

    final isSystem = message.sender.toLowerCase() == 'system' ||
        (message.type?.toLowerCase() == 'system');

    // System notice → centered + subtle
    if (isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        child: Center(
          child: Text(
            '[$time] ${message.content}',
            style: TextStyle(
              color: text.subtle.withValues(alpha: 0.9),
              fontStyle: FontStyle.italic,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Regular message → token bubble
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: TokenPanel(
              glass: style.glass,
              text: text,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              borderRadius: 12,
              child: RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 13, color: text.primary),
                  children: [
                    TextSpan(
                      text: '${message.sender} ',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: text.primary,
                      ),
                    ),
                    TextSpan(
                      text: '[$date $time]\n',
                      style: TextStyle(
                        fontSize: 11,
                        color: text.subtle.withValues(alpha: 0.9),
                      ),
                    ),
                    TextSpan(text: message.content),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
