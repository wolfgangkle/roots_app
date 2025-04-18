import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/auth_service.dart';
import '../auth/check_user_profile.dart';
import 'register_screen.dart';
import 'package:roots_app/modules/village/data/items.dart'; // ✅ Import gameItems

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String errorMessage = '';

  void _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.length < 6) {
      setState(() {
        errorMessage = 'Please enter a valid email and password (min. 6 characters).';
      });
      return;
    }

    setState(() => errorMessage = '');

    final auth = AuthService();
    final user = await auth.signIn(email, password);

    if (user == null) {
      setState(() {
        errorMessage = 'Authentication failed. Please check your credentials.';
      });
    } else {
      debugPrint('Logged in user: ${user.email}');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const CheckUserProfile(),
        ),
      );
    }
  }

  Future<void> _cleanMapTiles() async {
    final tilesRef = FirebaseFirestore.instance.collection('mapTiles');
    final snapshot = await tilesRef.get();

    int cleaned = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final cleanedData = {
        'terrain': data['terrain'],
        'x': data['x'],
        'y': data['y'],
      };

      final shouldClean = data.keys.any((k) => !['terrain', 'x', 'y'].contains(k));
      if (shouldClean) {
        await doc.reference.set(cleanedData, SetOptions(merge: false));
        cleaned++;
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("🧹 Cleaned $cleaned mapTiles")),
      );
    }
  }

  Future<void> _seedCraftingItems() async {
    final batch = FirebaseFirestore.instance.batch();
    final itemsRef = FirebaseFirestore.instance.collection('items');

    for (final entry in gameItems.entries) {
      final itemId = entry.key;
      final data = entry.value;

      final docRef = itemsRef.doc(itemId);
      batch.set(docRef, {
        'itemId': itemId,
        ...data,
      }, SetOptions(merge: true));
    }

    await batch.commit();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🧪 Seeded all crafting items into Firestore!")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submit,
              child: const Text('Login'),
            ),
            const SizedBox(height: 12),

            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                );
              },
              child: const Text("Don't have an account? Register here"),
            ),
            const SizedBox(height: 10),
            if (errorMessage.isNotEmpty)
              Text(errorMessage, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 20),

            // 🚀 Dev Quick Login buttons
            TextButton(
              onPressed: () async {
                final user = await AuthService().signIn("test3@roots.dev", "123456");
                if (user != null) {
                  debugPrint('Auto-logged in user: ${user.email}');
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const CheckUserProfile()),
                  );
                } else {
                  setState(() {
                    errorMessage = "Auto-login failed 😬";
                  });
                }
              },
              child: const Text("🚀 Dev Auto-Login (test3@roots.dev)"),
            ),
            TextButton(
              onPressed: () async {
                final user = await AuthService().signIn("test2@roots.dev", "123456");
                if (user != null) {
                  debugPrint('Auto-logged in user: ${user.email}');
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const CheckUserProfile()),
                  );
                } else {
                  setState(() {
                    errorMessage = "Auto-login failed 😬";
                  });
                }
              },
              child: const Text("🔁 Dev Auto-Login (test2@roots.dev)"),
            ),
            TextButton(
              onPressed: () async {
                final user = await AuthService().signIn("ivanna@roots.com", "123456");
                if (user != null) {
                  debugPrint('Auto-logged in user: ${user.email}');
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const CheckUserProfile()),
                  );
                } else {
                  setState(() {
                    errorMessage = "Auto-login failed 😬";
                  });
                }
              },
              child: const Text("🧪 Dev Auto-Login (ivanna@roots.com)"),
            ),
            TextButton(
              onPressed: () async {
                final user = await AuthService().signIn("test@roots.dev", "123456");
                if (user != null) {
                  debugPrint('Auto-logged in user: ${user.email}');
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const CheckUserProfile()),
                  );
                } else {
                  setState(() {
                    errorMessage = "Auto-login failed 😬";
                  });
                }
              },
              child: const Text("🧙 Dev Auto-Login (test@roots.dev)"),
            ),

            const SizedBox(height: 20),

            // 🧼 MapTiles Cleanup Button
            ElevatedButton.icon(
              icon: const Icon(Icons.cleaning_services),
              label: const Text("🧼 Clean mapTiles (terrain/x/y only)"),
              onPressed: _cleanMapTiles,
            ),
            const SizedBox(height: 12),

            // 🧪 Seed Crafting Items Button
            ElevatedButton.icon(
              icon: const Icon(Icons.bolt),
              label: const Text("🧪 Seed Crafting Items"),
              onPressed: _seedCraftingItems,
            ),
          ],
        ),
      ),
    );
  }
}
