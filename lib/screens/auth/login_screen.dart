import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/auth_service.dart';
import '../auth/check_user_profile.dart';
import 'register_screen.dart'; // ✅ Your new screen!

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

            /// 🔗 Register link
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

            /// 🚀 Dev button
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
          ],
        ),
      ),
    );
  }
}
