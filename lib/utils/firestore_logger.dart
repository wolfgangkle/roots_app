class FirestoreLogger {
  static void read(String from) {
    print("🔥 Firestore READ from: $from at ${DateTime.now()}");
  }

  static void write(String from) {
    print("📝 Firestore WRITE from: $from at ${DateTime.now()}");
  }

  static void delete(String from) {
    print("❌ Firestore DELETE from: $from at ${DateTime.now()}");
  }
}
