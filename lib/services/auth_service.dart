import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // for kDebugMode and debugPrint

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> signIn(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Sign-in failed: $e');
      }
      return null;
    }
  }

  Future<User?> register(String email, String password) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Registration failed: $e');
      }
      return null;
    }
  }

  Future<void> signOut() async => await _auth.signOut();
}
