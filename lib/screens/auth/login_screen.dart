import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../auth/check_user_profile.dart';
import 'register_screen.dart';
import 'package:roots_app/screens/dev/dev_tools_screen.dart'; // 🛠️ Dev screen

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _devPasswordController = TextEditingController();

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

    if (!mounted) return;

    if (user == null) {
      setState(() {
        errorMessage = 'Authentication failed. Please check your credentials.';
      });
    } else {
      debugPrint('Logged in user: ${user.email}');

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const CheckUserProfile()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              /// ✅ Always-visible dev login buttons
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildDevLoginButton("test3@roots.dev"),
                  _buildDevLoginButton("test2@roots.dev"),
                  _buildDevLoginButton("ivanna@roots.com"),
                  _buildDevLoginButton("test@roots.dev"),
                ],
              ),
              const Divider(height: 32),

              // Login Fields
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

              // 🛠️ Dev Mode Entry (optional fallback)
              const SizedBox(height: 30),
              const Divider(),
              TextField(
                controller: _devPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Dev Mode Password',
                  suffixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.vpn_key),
                label: const Text("Enter Dev Mode"),
                onPressed: () {
                  if (_devPasswordController.text.trim() == 'iamthedev') {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const DevToolsScreen()),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("❌ Wrong dev password")),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDevLoginButton(String email) {
    return TextButton(
      onPressed: () async {
        final user = await AuthService().signIn(email, "123456");

        if (!mounted) return;

        if (user != null) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const CheckUserProfile()),
                (route) => false,
          );
        } else {
          setState(() {
            errorMessage = "Auto-login failed 😬";
          });
        }
      },
      child: Text("🚀 Dev Login ($email)"),
    );
  }
}
