// lib/modules/chat/chat_input_field.dart

import 'package:flutter/material.dart';
import 'chat_service.dart';

class ChatInputField extends StatefulWidget {
  final String sender;

  const ChatInputField({super.key, required this.sender});

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  final _controller = TextEditingController();

  void _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    await ChatService.sendMessage(widget.sender, text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              onSubmitted: (_) => _send(),
              decoration: const InputDecoration(
                hintText: 'Type your message...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _send,
          ),
        ],
      ),
    );
  }
}
