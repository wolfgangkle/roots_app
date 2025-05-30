import 'package:flutter/material.dart';
import 'package:roots_app/modules/chat/chat_service.dart';

class GuildChatInputField extends StatefulWidget {
  final String guildId;
  final String sender;

  const GuildChatInputField({
    super.key,
    required this.guildId,
    required this.sender,
  });

  @override
  State<GuildChatInputField> createState() => _GuildChatInputFieldState();
}

class _GuildChatInputFieldState extends State<GuildChatInputField> {
  final _controller = TextEditingController();

  void _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    await ChatService.sendGuildMessage(widget.guildId, widget.sender, text);
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
