import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/auth_service.dart';
import '../auth/check_user_profile.dart'; // 🔧 Make sure this path is correct for your project

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: "test@roots.dev"); // 💡 Pre-filled
  final _passwordController = TextEditingController(text: "123456");       // 💡 Pre-filled
  bool isLoginMode = true;
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
    User? user;

    if (isLoginMode) {
      user = await auth.signIn(email, password);
    } else {
      user = await auth.register(email, password);
    }

    if (user == null) {
      setState(() {
        errorMessage = 'Authentication failed. Please check your credentials.';
      });
    } else {
      // Debug print: Log the user's email (or other details)
      debugPrint('Logged in user: ${user.email}');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const CheckUserProfile(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isLoginMode ? 'Login' : 'Register')),
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
              child: Text(isLoginMode ? 'Login' : 'Register'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() => isLoginMode = !isLoginMode),
              child: Text(isLoginMode
                  ? 'Need an account? Register'
                  : 'Already have an account? Login'),
            ),
            const SizedBox(height: 10),
            if (errorMessage.isNotEmpty)
              Text(errorMessage, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () async {
                final user = await AuthService().signIn("test@roots.dev", "123456");
                if (user != null) {
                  // Debug print for auto login as well
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
              child: const Text("🚀 Dev Auto-Login (test@roots.dev)"),
            ),
          ],
        ),
      ),
    );
  }
}
