import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roots_app/modules/chat/chat_service.dart';
import 'package:roots_app/modules/chat/chat_message_model.dart';
import 'package:roots_app/profile/models/user_profile_model.dart';

class ChatOverlay extends StatefulWidget {
  const ChatOverlay({super.key});

  @override
  State<ChatOverlay> createState() => _ChatOverlayState();
}

class _ChatOverlayState extends State<ChatOverlay> {
  final TextEditingController _controller = TextEditingController();

  void _sendMessage(String sender) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    ChatService.sendMessage(sender, text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final heroName = Provider.of<UserProfileModel>(context, listen: false).heroName;

    return Positioned(
      right: 16,
      bottom: 16,
      child: Container(
        width: 300,
        height: 180,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('💬 Global Chat',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Expanded(
              child: StreamBuilder<List<ChatMessage>>(
                stream: ChatService.getMessageStream(limit: 10),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox();

                  final messages = snapshot.data!;
                  return ListView(
                    reverse: true,
                    children: messages.map((msg) {
                      return Text(
                        '${msg.sender}: ${msg.content}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Type message...',
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 6),
                    ),
                    onSubmitted: (_) => _sendMessage(heroName),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: () => _sendMessage(heroName),
                  padding: EdgeInsets.zero,
                  iconSize: 20,
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
