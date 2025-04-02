import 'package:flutter/material.dart';

class ChatPanel extends StatelessWidget {
  const ChatPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: const [
        Text('💬 Zone Chat', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        Text('🧝 Marla: Anyone near tile 12,20?'),
        Text('🧙 Darik: Heading that way now.'),
        Text('🧟 UndeadLord69: brains plz'),
        SizedBox(height: 20),
        TextField(
          decoration: InputDecoration(
            hintText: 'Type your message...',
            border: OutlineInputBorder(),
          ),
        )
      ],
    );
  }
}
