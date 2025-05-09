import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../auth/check_user_profile.dart';
import 'register_screen.dart';
import 'package:roots_app/screens/dev/seed_functions.dart';

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
  bool _devModeEnabled = false;

  void _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.length < 6) {
      setState(() {
        errorMessage =
            'Please enter a valid email and password (min. 6 characters).';
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
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const CheckUserProfile()),
        (route) => false,
      );
    }
  }

  void _tryEnableDevMode() {
    final password = _devPasswordController.text.trim();
    if (password == 'iamthedev') {
      setState(() => _devModeEnabled = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🔓 Dev mode activated")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Wrong dev password")),
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
          children: [
            if (_devModeEnabled) ...[
              // 🌿 AI + Seeding Buttons (only in dev mode)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text("🌿 AI Peaceful"),
                      onPressed: () => triggerPeacefulAIEvent(context),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.auto_awesome_motion),
                      label: const Text("⚔️ AI Combat"),
                      onPressed: () => triggerCombatAIEvent(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.cleaning_services),
                label: const Text("🧼 Clean mapTiles (terrain/x/y only)"),
                onPressed: () => cleanMapTiles(context),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.bolt),
                label: const Text("⚒️ Seed Crafting Items"),
                onPressed: () => seedCraftingItems(context),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.shield),
                label: const Text("💀 Seed Enemies"),
                onPressed: () => seedEnemies(context),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.local_fire_department),
                label: const Text("🧪 Seed Encounter Events"),
                onPressed: () => seedEncounterEvents(context),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.auto_fix_high),
                label: const Text("✨ Seed Spells"),
                onPressed: () => seedSpells(context),
              ),

              const SizedBox(height: 24),
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
            ],

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

            // 🛠️ Dev Mode Entry
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
              onPressed: _tryEnableDevMode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDevLoginButton(String email) {
    return TextButton(
      onPressed: () async {
        final user = await AuthService().signIn(email, "123456");
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
