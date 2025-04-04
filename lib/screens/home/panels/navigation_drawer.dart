import 'package:flutter/material.dart';

class NavigationDrawerPanel extends StatelessWidget {
  const NavigationDrawerPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text('🏠 Home'),
          SizedBox(height: 12),
          Text('🗺️ Map'),
          SizedBox(height: 12),
          Text('🏡 Village'),
          SizedBox(height: 12),
          Text('🧙 Hero'),
          SizedBox(height: 12),
          Text('💬 Chat'),
          SizedBox(height: 12),
          Text('⚙️ Settings'),
        ],
      ),
    );
  }
}
