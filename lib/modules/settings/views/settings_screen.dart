import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roots_app/modules/settings/models/user_settings_model.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<UserSettingsModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('🌗 Embrace the Darkness'),
                  subtitle: const Text('Toggle dark fantasy theme'),
                  value: settings.darkMode,
                  onChanged: settings.setDarkMode,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                const Divider(height: 0),
                SwitchListTile(
                  title: const Text('💬 Show Global Chat Overlay'),
                  value: settings.showChatOverlay,
                  onChanged: settings.setShowChatOverlay,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
