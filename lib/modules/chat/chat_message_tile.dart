import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'chat_message_model.dart';

class ChatMessageTile extends StatelessWidget {
  final ChatMessage message;

  const ChatMessageTile({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd.MM.yyyy').format(message.timestamp);
    final time = DateFormat.Hm().format(message.timestamp); // HH:mm

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '[$date $time] ',
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
