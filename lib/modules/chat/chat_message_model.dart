import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String sender;
  final String content;
  final DateTime timestamp;
  final String? type; // 👈 Support for system messages

  ChatMessage({
    required this.id,
    required this.sender,
    required this.content,
    required this.timestamp,
    this.type,
  });

  factory ChatMessage.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      sender: data['sender'] ?? 'Unknown',
      content: data['content'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      type: data['type'], // 👈 Deserializing system/admin/etc. types
    );
  }

  Map<String, dynamic> toMap() => {
    'sender': sender,
    'content': content,
    'timestamp': FieldValue.serverTimestamp(),
    if (type != null) 'type': type,
  };
}
