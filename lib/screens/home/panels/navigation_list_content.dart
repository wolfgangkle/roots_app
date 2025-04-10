// lib/screens/home/panels/navigation_list_content.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:roots_app/screens/controllers/main_content_controller.dart';
import 'package:roots_app/modules/chat/chat_screen.dart';
import 'package:roots_app/screens/auth/login_screen.dart';
import 'package:roots_app/screens/dev/dev_mode.dart';

class NavigationListContent extends StatelessWidget {
  const NavigationListContent({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDevUser = user?.email == 'test@roots.dev';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('🏠 Home'),
        const SizedBox(height: 12),
        const Text('🗺️ Map'),
        const SizedBox(height: 12),
        const Text('🏡 Village'),
        const SizedBox(height: 12),
        const Text('🧙 Hero'),
        const SizedBox(height: 12),
        ListTile(
          leading: const Icon(Icons.chat),
          title: const Text('💬 Chat'),
          onTap: () {
            Provider.of<MainContentController>(context, listen: false)
                .setCustomContent(ChatScreen());
          },
        ),
        const SizedBox(height: 12),
        const Text('⚙️ Settings'),
        const SizedBox(height: 24),
        if (isDevUser) ...[
          const Divider(),
          const Text('🧪 Dev Tools', style: TextStyle(fontWeight: FontWeight.bold)),
          SwitchListTile(
            title: const Text('Dev Mode'),
            value: DevMode.enabled,
            onChanged: (val) {
              DevMode.enabled = val;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(val ? 'Dev Mode Enabled' : 'Dev Mode Disabled')),
              );
            },
          ),
        ],
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Logout'),
          onTap: () async {
            await FirebaseAuth.instance.signOut();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          },
        ),
      ],
    );
  }
}
