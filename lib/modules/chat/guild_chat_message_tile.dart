import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'chat_message_model.dart';

class GuildChatMessageTile extends StatelessWidget {
  final ChatMessage message;

  const GuildChatMessageTile({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final time = DateFormat.Hm().format(message.timestamp); // HH:mm

    final isSystem = message.sender.toLowerCase() == 'system' ||
        (message.type?.toLowerCase() == 'system');

    if (isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 12),
        child: Center(
          child: Text(
            '[$time] ${message.content}',
            style: const TextStyle(
              color: Colors.grey,
              fontStyle: FontStyle.italic,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '[$time] ',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13, color: Colors.black),
                children: [
                  TextSpan(
                    text: '${message.sender}: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: message.content),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
