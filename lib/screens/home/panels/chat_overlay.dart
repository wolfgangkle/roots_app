import 'package:flutter/material.dart';

class ChatOverlay extends StatelessWidget {
  const ChatOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: 16,
      child: Container(
        width: 300,
        height: 180,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.75),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('💬 World Chat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('🧝 Marla: Hello world!', style: TextStyle(color: Colors.white)),
            Text('🧙 Darik: We live!', style: TextStyle(color: Colors.white)),
            Spacer(),
            TextField(
              decoration: InputDecoration(
                hintText: 'Type message...',
                hintStyle: TextStyle(color: Colors.white54),
                border: InputBorder.none,
              ),
              style: TextStyle(color: Colors.white),
            )
          ],
        ),
      ),
    );
  }
}
