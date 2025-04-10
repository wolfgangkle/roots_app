import 'package:flutter/material.dart';
import 'package:roots_app/modules/chat/chat_service.dart';
import 'package:roots_app/modules/chat/chat_message_tile.dart';
import 'package:roots_app/modules/chat/chat_input_field.dart';
import 'package:roots_app/modules/chat/chat_message_model.dart';

class ChatPanel extends StatelessWidget {
  final String currentUserName;

  const ChatPanel({super.key, required this.currentUserName});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            '💬 Global Chat',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<ChatMessage>>(
            stream: ChatService.getMessageStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final messages = snapshot.data ?? [];

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                reverse: true, // Newest messages at the bottom
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[messages.length - index - 1];
                  return ChatMessageTile(message: message);
                },
              );
            },
          ),
        ),
        ChatInputField(sender: currentUserName),
      ],
    );
  }
}
