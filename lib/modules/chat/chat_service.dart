import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_message_model.dart';
import 'package:roots_app/utils/firestore_logger.dart';

class ChatService {
  static final _messagesRef = FirebaseFirestore.instance
      .collection('chats')
      .doc('global')
      .collection('messages');

  /// Stream the latest [limit] messages (default: 100) from global chat
  static Stream<List<ChatMessage>> getMessageStream({int limit = 100}) {
    FirestoreLogger.read("getMessageStream (limit: $limit)");

    return _messagesRef
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      FirestoreLogger.read(
          "getMessageStream → snapshot (${snapshot.docs.length} docs)");
      return snapshot.docs
          .map((doc) => ChatMessage.fromDoc(doc))
          .toList()
          .reversed
          .toList(); // newest at bottom
    });
  }

  /// Send a new global message
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
    final allMessages =
        await _messagesRef.orderBy('timestamp', descending: true).get();

    FirestoreLogger.read("prune - total messages: ${allMessages.docs.length}");

    final docsToDelete = allMessages.docs.skip(maxMessages).toList();

    if (docsToDelete.isNotEmpty) {
      FirestoreLogger.delete(
          "prune - deleting ${docsToDelete.length} message(s)");
    }

    for (final doc in docsToDelete) {
      await doc.reference.delete();
      FirestoreLogger.delete("prune - deleted doc ${doc.id}");
    }
  }

  /// Stream messages from guild chat
  static Stream<List<ChatMessage>> getGuildMessageStream(String guildId,
      {int limit = 100}) {
    final ref = FirebaseFirestore.instance
        .collection('guilds')
        .doc(guildId)
        .collection('chat')
        .orderBy('timestamp', descending: true)
        .limit(limit);

    return ref.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatMessage.fromDoc(doc))
          .toList()
          .reversed
          .toList();
    });
  }

  /// Send a message to the guild chat
  static Future<void> sendGuildMessage(
      String guildId, String sender, String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return;

    FirestoreLogger.write('sendGuildMessage from $sender to $guildId');

    final ref = FirebaseFirestore.instance
        .collection('guilds')
        .doc(guildId)
        .collection('chat');

    await ref.add({
      'sender': sender,
      'content': trimmed,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Send a system message to the guild chat (e.g. "Ivanna joined the guild")
  static Future<void> sendSystemGuildMessage(
      String guildId, String content) async {
    FirestoreLogger.write('sendSystemGuildMessage to $guildId → "$content"');

    final ref = FirebaseFirestore.instance
        .collection('guilds')
        .doc(guildId)
        .collection('chat');

    await ref.add({
      'sender': 'System',
      'content': content,
      'type': 'system',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
