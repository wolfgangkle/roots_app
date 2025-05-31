import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:roots_app/screens/controllers/main_content_controller.dart';
import 'package:roots_app/modules/chat/chat_screen.dart';
import 'package:roots_app/screens/auth/login_screen.dart';
import 'package:roots_app/modules/reports/views/reports_list_screen.dart';
import 'package:roots_app/screens/helpers/layout_helper.dart';
import 'package:roots_app/modules/settings/views/settings_screen.dart';
import 'package:roots_app/modules/map/screens/map_grid_view.dart';
import 'package:roots_app/modules/guild/views/guild_screen.dart';
import 'package:roots_app/modules/guild/views/create_guild_screen.dart';
import 'package:roots_app/modules/guild/views/browse_guilds_placeholder.dart';
import 'package:roots_app/modules/profile/models/user_profile_model.dart';
import 'package:roots_app/modules/guild/views/guild_members_screen.dart';
import 'package:roots_app/modules/guild/views/guild_invite_inbox_screen.dart';
import 'package:roots_app/modules/guild/views/guild_settings_screen.dart';
import 'package:roots_app/modules/chat/guild_chat_panel.dart';
import 'package:roots_app/modules/alliances/views/create_alliance_screen.dart';
import 'package:roots_app/modules/alliances/views/alliance_members_screen.dart';
import 'package:roots_app/modules/alliances/views/alliance_invite_inbox_screen.dart';
import 'package:roots_app/modules/reports/views/finished_jobs_screen.dart';
import 'package:roots_app/screens/helpers/finished_jobs_tab_tile.dart';
import 'package:roots_app/modules/profile/views/player_leaderboard_screen.dart';
import 'package:roots_app/modules/profile/views/guild_leaderboard_screen.dart';
import 'package:roots_app/modules/profile/views/alliance_leaderboard_screen.dart';

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
    final profile = context.watch<UserProfileModel>();
    final hasGuild = profile.guildId != null;
    final isLeader = profile.guildRole == 'leader';
    final isOfficer = profile.guildRole == 'officer';
    final hasAlliance = profile.allianceId != null;

    final screenWidth = MediaQuery.of(context).size.width;
    final screenSize = LayoutHelper.getSizeCategory(screenWidth);
    final isMobile = screenSize == ScreenSizeCategory.small;

    final sectionHeaderStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.bold,
      color: Theme.of(context).colorScheme.onSurface,
    );

    final inviteStream = FirebaseFirestore.instance
        .collection('guildInvites')
        .where('toUserId', isEqualTo: user?.uid)
        .where('status', isEqualTo: 'pending')
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: inviteStream,
      builder: (context, guildInviteSnapshot) {
        final hasGuildInvites = guildInviteSnapshot.data?.docs.isNotEmpty ?? false;

        if (hasGuild && isLeader && profile.guildId != null) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('guilds')
                .doc(profile.guildId!)
                .collection('allianceInvites')
                .snapshots(),
            builder: (context, allianceInviteSnapshot) {
              final hasAllianceInvites = allianceInviteSnapshot.data?.docs.isNotEmpty ?? false;
              return _buildNavigation(
                context,
                profile,
                hasGuild,
                isLeader,
                isOfficer,
                hasAlliance,
                isMobile,
                sectionHeaderStyle,
                hasGuildInvites,
                hasAllianceInvites,
              );
            },
          );
        }

        return _buildNavigation(
          context,
          profile,
          hasGuild,
          isLeader,
          isOfficer,
          hasAlliance,
          isMobile,
          sectionHeaderStyle,
          hasGuildInvites,
          false,
        );
      },
    );
  }

  Widget _buildNavigation(
      BuildContext context,
      UserProfileModel profile,
      bool hasGuild,
      bool isLeader,
      bool isOfficer,
      bool hasAlliance,
      bool isMobile,
      TextStyle? sectionHeaderStyle,
      bool hasGuildInvites,
      bool hasAllianceInvites,
      ) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      children: [
        Text('🔔 Notifications', style: sectionHeaderStyle),
        _buildTabTile(context, isMobile, 'Event Logs', const ReportsListScreen()),
        FinishedJobsTabTile(
          isMobile: isMobile,
          isInDrawer: isInDrawer,
          onSelectDynamicTab: onSelectDynamicTab,
        ),
        if (hasGuildInvites)
          _buildTabTile(context, isMobile, 'Guild Invites', const GuildInviteInboxScreen()),
        if (hasAllianceInvites)
          _buildTabTile(context, isMobile, 'Alliance Invites', const AllianceInviteInboxScreen()),

        const SizedBox(height: 12),
        Text('🌍 World', style: sectionHeaderStyle),
        _buildTabTile(context, isMobile, '🌍 Map', const MapGridView()),

        const SizedBox(height: 12),
        Text('🏰 Guild', style: sectionHeaderStyle),
        if (!hasGuild) ...[
          _buildTabTile(context, isMobile, 'Create Guild', const CreateGuildScreen()),
          _buildTabTile(context, isMobile, 'Browse Guilds', const BrowseGuildsPlaceholder()),
        ] else ...[
          _buildTabTile(context, isMobile, 'Guild Dashboard', const GuildScreen()),
          _buildTabTile(context, isMobile, 'Members', const GuildMembersScreen()),
          if (isLeader)
            _buildTabTile(context, isMobile, 'Guild Settings', const GuildSettingsScreen()),
        ],

        if ((hasAlliance || (hasGuild && isLeader && !hasAlliance))) ...[
          const SizedBox(height: 12),
          Text('🤝 Alliance', style: sectionHeaderStyle),
          if (hasGuild && isLeader && !hasAlliance)
            _buildTabTile(context, isMobile, 'Create Alliance', const CreateAllianceScreen()),
          if (hasAlliance)
            _buildTabTile(context, isMobile, 'Alliance Members', const AllianceMembersScreen()),
        ],

        const SizedBox(height: 12),
        Text('📊 Leaderboards', style: sectionHeaderStyle),
        _buildTabTile(context, isMobile, 'Players', const PlayerLeaderboardScreen()),
        _buildTabTile(context, isMobile, 'Guilds', const GuildLeaderboardScreen()),
        _buildTabTile(context, isMobile, 'Alliances', const AllianceLeaderboardScreen()),

        const SizedBox(height: 12),
        Text('💬 Chat', style: sectionHeaderStyle),
        _buildTabTile(context, isMobile, 'Global Chat', ChatScreen()),
        if (hasGuild)
          _buildTabTile(context, isMobile, 'Guild Chat', const GuildChatPanel()),

        const SizedBox(height: 12),
        Text('⚙️ Settings', style: sectionHeaderStyle),
        _buildTabTile(context, isMobile, 'Settings', const SettingsScreen()),
        const Divider(),
        ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.onSurface),
          title: Text('Logout', style: Theme.of(context).textTheme.bodyLarge),
          onTap: () async {
            final navigator = Navigator.of(context);
            await FirebaseAuth.instance.signOut();
            navigator.pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
            );
          },
        ),
      ],
    );
  }

  Widget _buildTabTile(BuildContext context, bool isMobile, String title, Widget content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        dense: true,
        visualDensity: VisualDensity.compact,
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
      ),
    );
  }
}
