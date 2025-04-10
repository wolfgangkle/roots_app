import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_message_model.dart';

class ChatService {
  static final _messagesRef = FirebaseFirestore.instance
      .collection('chats')
      .doc('global')
      .collection('messages');

  /// Stream the latest [limit] messages (default: 100)
  static Stream<List<ChatMessage>> getMessageStream({int limit = 100}) {
    return _messagesRef
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ChatMessage.fromDoc(doc))
        .toList()
        .reversed
        .toList()); // newest at bottom
  }

  /// Send a new message
  static Future<void> sendMessage(String sender, String content) async {
    if (content.trim().isEmpty) return;

    // Add the new message
    await _messagesRef.add({
      'sender': sender,
      'content': content.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Prune old messages (keep only the latest 100)
    await _pruneOldMessages(maxMessages: 100);
  }

  /// Delete messages beyond the latest [maxMessages]
  static Future<void> _pruneOldMessages({int maxMessages = 100}) async {
    final allMessages = await _messagesRef
        .orderBy('timestamp', descending: true)
        .get();

    final docsToDelete = allMessages.docs.skip(maxMessages).toList();

    for (final doc in docsToDelete) {
      await doc.reference.delete();
    }
  }
}
