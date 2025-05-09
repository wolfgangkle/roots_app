import 'package:flutter/foundation.dart';

class FirestoreLogger {
  static void read(String from) {
    if (kDebugMode) {
      debugPrint("🔥 Firestore READ from: $from at ${DateTime.now()}");
    }
  }

  static void write(String from) {
    if (kDebugMode) {
      debugPrint("📝 Firestore WRITE from: $from at ${DateTime.now()}");
    }
  }

  static void delete(String from) {
    if (kDebugMode) {
      debugPrint("❌ Firestore DELETE from: $from at ${DateTime.now()}");
    }
  }
}
