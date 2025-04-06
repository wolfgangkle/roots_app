import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NavigationDrawerPanel extends StatefulWidget {
  const NavigationDrawerPanel({super.key});

  @override
  State<NavigationDrawerPanel> createState() => _NavigationDrawerPanelState();
}

class _NavigationDrawerPanelState extends State<NavigationDrawerPanel> {
  bool devModeEnabled = false;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDevUser = user?.email == 'test@roots.dev';

    return Drawer(
      child: ListView(
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
          const Text('💬 Chat'),
          const SizedBox(height: 12),
          const Text('⚙️ Settings'),
          const SizedBox(height: 24),

          if (isDevUser) ...[
            const Divider(),
            const Text('🧪 Dev Tools', style: TextStyle(fontWeight: FontWeight.bold)),
            SwitchListTile(
              title: const Text('Dev Mode'),
              value: devModeEnabled,
              onChanged: (val) {
                setState(() => devModeEnabled = val);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(val ? 'Dev Mode Enabled' : 'Dev Mode Disabled')),
                );
              },
            ),
            if (devModeEnabled)
              ListTile(
                leading: const Icon(Icons.map),
                title: const Text('Map Editor'),
                onTap: () {
                  Navigator.pop(context); // close drawer
                  Navigator.pushNamed(context, '/map_editor');
                },
              ),
          ],
        ],
      ),
    );
  }
}
