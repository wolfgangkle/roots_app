import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:roots_app/screens/controllers/main_content_controller.dart';
import 'package:roots_app/modules/chat/chat_screen.dart';
import 'package:roots_app/screens/auth/login_screen.dart';
import 'package:roots_app/screens/dev/dev_mode.dart';
import 'package:roots_app/modules/reports/views/reports_list_screen.dart';
import 'package:roots_app/screens/helpers/layout_helper.dart';
import 'package:roots_app/modules/settings/views/settings_screen.dart';
import 'package:roots_app/modules/map/screens/map_grid_view.dart';
import 'package:roots_app/modules/guild/views/guild_screen.dart';
import 'package:roots_app/modules/guild/views/create_guild_screen.dart';
import 'package:roots_app/modules/guild/views/browse_guilds_placeholder.dart';
import 'package:roots_app/profile/models/user_profile_model.dart';
import 'package:roots_app/modules/guild/views/guild_members_screen.dart';
import 'package:roots_app/modules/guild/views/guild_role_manager_screen.dart';
import 'package:roots_app/modules/guild/views/guild_invite_inbox_screen.dart';
import 'package:roots_app/modules/guild/views/guild_settings_screen.dart';
import 'package:roots_app/modules/chat/guild_chat_panel.dart';




class NavigationListContent extends StatelessWidget {
  final void Function({required String title, required Widget content})? onSelectDynamicTab;
  final bool isInDrawer;

  const NavigationListContent({
    super.key,
    this.onSelectDynamicTab,
    this.isInDrawer = false,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDevUser = user?.email == 'test@roots.dev';

    final profile = context.watch<UserProfileModel>();
    final hasGuild = profile.guildId != null;
    final isLeader = profile.guildRole == 'leader';
    final isOfficer = profile.guildRole == 'officer';

    final screenWidth = MediaQuery.of(context).size.width;
    final screenSize = LayoutHelper.getSizeCategory(screenWidth);
    final isMobile = screenSize == ScreenSizeCategory.small;

    if (isDevUser) {
      DevMode.enabled = true;
    }

    final sectionHeaderStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.bold,
      color: Theme.of(context).colorScheme.onSurface,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('🌍 World', style: sectionHeaderStyle),
        const SizedBox(height: 12),
        _buildTabTile(context, isMobile, '🌍 Map', const MapGridView()),

        const SizedBox(height: 24),
        Text('🏰 Guild', style: sectionHeaderStyle),
        const SizedBox(height: 12),
        if (!hasGuild) ...[
          _buildTabTile(context, isMobile, 'Create Guild', const CreateGuildScreen()),
          _buildTabTile(context, isMobile, 'Browse Guilds', const BrowseGuildsPlaceholder()),
        ] else ...[
          _buildTabTile(context, isMobile, 'Guild Dashboard', const GuildScreen()),
          _buildTabTile(context, isMobile, 'Members', const GuildMembersScreen()),
          if (isLeader || isOfficer)
            _buildTabTile(context, isMobile, 'Manage Roles', const GuildRoleManagerScreen()),
          if (isLeader)
            _buildTabTile(context, isMobile, 'Guild Settings', const GuildSettingsScreen()),
        ],

        const SizedBox(height: 24),
        Text('💬 Chat', style: sectionHeaderStyle),
        const SizedBox(height: 12),
        _buildTabTile(context, isMobile, 'Global Chat', ChatScreen()),
        if (hasGuild)
          _buildTabTile(context, isMobile, 'Guild Chat', const GuildChatPanel()),


        const SizedBox(height: 24),
        Text('🔔 Notifications', style: sectionHeaderStyle),
        const SizedBox(height: 12),
        _buildTabTile(context, isMobile, 'Event Logs', const ReportsListScreen()),
        _buildTabTile(context, isMobile, 'Finished Jobs', const Placeholder()),
        _buildTabTile(context, isMobile, 'Guild Invites', const GuildInviteInboxScreen()),


        const SizedBox(height: 24),
        Text('⚙️ Settings', style: sectionHeaderStyle),
        const SizedBox(height: 12),
        _buildTabTile(context, isMobile, 'Settings', const SettingsScreen()),

        const SizedBox(height: 24),
        const Divider(),
        ListTile(
          leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.onSurface),
          title: Text('Logout', style: Theme.of(context).textTheme.bodyLarge),
          onTap: () async {
            await FirebaseAuth.instance.signOut();
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
            );
          },
        ),
      ],
    );
  }

  Widget _buildTabTile(BuildContext context, bool isMobile, String title, Widget content) {
    return ListTile(
      leading: Icon(Icons.arrow_right, color: Theme.of(context).colorScheme.onSurface),
      title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
      onTap: () {
        if (isInDrawer) Navigator.pop(context);

        if (isMobile && onSelectDynamicTab != null) {
          onSelectDynamicTab!(title: title, content: content);
        } else {
          final controller = Provider.of<MainContentController>(context, listen: false);
          controller.setCustomContent(content);
        }
      },
    );
  }
}
