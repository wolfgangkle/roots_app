import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roots_app/modules/settings/models/user_settings_model.dart';
import 'package:roots_app/theme/app_style_manager.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<UserSettingsModel>();
    final styleMgr = context.watch<StyleManager>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 🎨 Theme / Style picker
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ListTile(
                  title: Text('🎨 App Style'),
                  subtitle: Text('Choose your UI theme'),
                ),
                RadioListTile<AppTheme>(
                  title: const Text('Dark Forge'),
                  subtitle: const Text('Dark, moody, glassy'),
                  value: AppTheme.darkForge,
                  groupValue: styleMgr.current,
                  onChanged: (v) => context.read<StyleManager>().setTheme(v!),
                ),
                const Divider(height: 0),
                RadioListTile<AppTheme>(
                  title: const Text('Silver Grove'),
                  subtitle: const Text('Bright, frosted, bluish accent'),
                  value: AppTheme.silverGrove,
                  groupValue: styleMgr.current,
                  onChanged: (v) => context.read<StyleManager>().setTheme(v!),
                ),
                const Divider(height: 0),
                RadioListTile<AppTheme>(
                  title: const Text('Iron Keep (Solid)'),
                  subtitle: const Text('Opaque, medieval, non-glass'),
                  value: AppTheme.ironKeep, // 👈 new theme option
                  groupValue: styleMgr.current,
                  onChanged: (v) => context.read<StyleManager>().setTheme(v!),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 💬 Other toggles you already had
          Card(
            child: Column(
              children: [
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
