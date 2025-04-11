import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_message_model.dart';
import 'package:roots_app/utils/firestore_logger.dart'; // ✅ Import your logger

class ChatService {
  static final _messagesRef = FirebaseFirestore.instance
      .collection('chats')
      .doc('global')
      .collection('messages');

  /// Stream the latest [limit] messages (default: 100)
  static Stream<List<ChatMessage>> getMessageStream({int limit = 100}) {
    FirestoreLogger.read("getMessageStream (limit: $limit)");

    return _messagesRef
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      FirestoreLogger.read("getMessageStream → snapshot (${snapshot.docs.length} docs)");
      return snapshot.docs
          .map((doc) => ChatMessage.fromDoc(doc))
          .toList()
          .reversed
          .toList(); // newest at bottom
    });
  }

  /// Send a new message
  static Future<void> sendMessage(String sender, String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return;

    FirestoreLogger.write('sendMessage from $sender');

    await _messagesRef.add({
      'sender': sender,
      'content': trimmed,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await _pruneOldMessages(maxMessages: 100);
  }

  /// Delete messages beyond the latest [maxMessages]
  static Future<void> _pruneOldMessages({int maxMessages = 100}) async {
    final allMessages = await _messagesRef
        .orderBy('timestamp', descending: true)
        .get();

    FirestoreLogger.read("prune - total messages: ${allMessages.docs.length}");

    final docsToDelete = allMessages.docs.skip(maxMessages).toList();

    if (docsToDelete.isNotEmpty) {
      FirestoreLogger.delete("prune - deleting ${docsToDelete.length} message(s)");
    }

    for (final doc in docsToDelete) {
      await doc.reference.delete();
      FirestoreLogger.delete("prune - deleted doc ${doc.id}");
    }
  }
}
