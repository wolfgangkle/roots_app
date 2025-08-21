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
import 'package:roots_app/screens/helpers/finished_jobs_tab_tile.dart';
import 'package:roots_app/modules/profile/views/player_leaderboard_screen.dart';
import 'package:roots_app/modules/profile/views/guild_leaderboard_screen.dart';
import 'package:roots_app/modules/profile/views/alliance_leaderboard_screen.dart';
import 'package:roots_app/modules/map/screens/world_map_screen.dart';
import 'package:roots_app/theme/tokens.dart';
import 'package:roots_app/theme/app_style_manager.dart';

TextOnGlassTokens get _text => kStyle.textOnGlass;

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
    // 👇 Rebuild when theme changes
    context.watch<StyleManager>();

    final user = FirebaseAuth.instance.currentUser;
    final profile = context.watch<UserProfileModel>();
    final hasGuild = profile.guildId != null;
    final isLeader = profile.guildRole == 'leader';
    final isOfficer = profile.guildRole == 'officer';
    final hasAlliance = profile.allianceId != null;

    final screenWidth = MediaQuery.of(context).size.width;
    final screenSize = LayoutHelper.getSizeCategory(screenWidth);
    final isMobile = screenSize == ScreenSizeCategory.small;

    // 🌟 Token-based section headers
    final sectionHeaderStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
      color: _text.primary.withOpacity(0.92),
    );

    // Standardize tile title style once
    final tileTitleStyle =
    Theme.of(context).textTheme.bodyLarge?.copyWith(color: _text.primary);

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
                tileTitleStyle,
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
          tileTitleStyle,
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
      TextStyle? tileTitleStyle,
      bool hasGuildInvites,
      bool hasAllianceInvites,
      ) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerTheme: DividerThemeData(
          color: _text.subtle.withOpacity(0.20),
          thickness: 1,
          space: 12,
        ),
      ),
      child: ListTileTheme(
        textColor: _text.primary,
        iconColor: _text.secondary.withOpacity(0.9),
        child: DefaultTextStyle(
          style: tileTitleStyle ?? const TextStyle(),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              Text('🔔 Notifications', style: sectionHeaderStyle),
              _buildTabTile(context, isMobile, 'Event Logs', const ReportsListScreen(), tileTitleStyle),

              FinishedJobsTabTile(
                isMobile: isMobile,
                isInDrawer: isInDrawer,
                onSelectDynamicTab: onSelectDynamicTab,
              ),

              if (hasGuildInvites)
                _buildTabTile(context, isMobile, 'Guild Invites', const GuildInviteInboxScreen(), tileTitleStyle),
              if (hasAllianceInvites)
                _buildTabTile(context, isMobile, 'Alliance Invites', const AllianceInviteInboxScreen(), tileTitleStyle),

              const SizedBox(height: 12),
              Text('🌍 World', style: sectionHeaderStyle),
              _buildTabTile(context, isMobile, '🌍 Map (legacy)', const MapGridView(), tileTitleStyle),
              ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                leading: const Icon(Icons.arrow_right),
                title: Text('🗺️ World Map', style: tileTitleStyle),
                onTap: () {
                  if (isInDrawer) Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const WorldMapScreen()),
                  );
                },
              ),

              const SizedBox(height: 12),
              Text('🏰 Guild', style: sectionHeaderStyle),
              if (!hasGuild) ...[
                _buildTabTile(context, isMobile, 'Create Guild', const CreateGuildScreen(), tileTitleStyle),
                _buildTabTile(context, isMobile, 'Browse Guilds', const BrowseGuildsPlaceholder(), tileTitleStyle),
              ] else ...[
                _buildTabTile(context, isMobile, 'Guild Dashboard', const GuildScreen(), tileTitleStyle),
                _buildTabTile(context, isMobile, 'Members', const GuildMembersScreen(), tileTitleStyle),
                if (isLeader)
                  _buildTabTile(context, isMobile, 'Guild Settings', const GuildSettingsScreen(), tileTitleStyle),
              ],

              if ((hasAlliance || (hasGuild && isLeader && !hasAlliance))) ...[
                const SizedBox(height: 12),
                Text('🤝 Alliance', style: sectionHeaderStyle),
                if (hasGuild && isLeader && !hasAlliance)
                  _buildTabTile(context, isMobile, 'Create Alliance', const CreateAllianceScreen(), tileTitleStyle),
                if (hasAlliance)
                  _buildTabTile(context, isMobile, 'Alliance Members', const AllianceMembersScreen(), tileTitleStyle),
              ],

              const SizedBox(height: 12),
              Text('📊 Leaderboards', style: sectionHeaderStyle),
              _buildTabTile(context, isMobile, 'Players', const PlayerLeaderboardScreen(), tileTitleStyle),
              _buildTabTile(context, isMobile, 'Guilds', const GuildLeaderboardScreen(), tileTitleStyle),
              _buildTabTile(context, isMobile, 'Alliances', const AllianceLeaderboardScreen(), tileTitleStyle),

              const SizedBox(height: 12),
              Text('💬 Chat', style: sectionHeaderStyle),
              _buildTabTile(context, isMobile, 'Global Chat', ChatScreen(), tileTitleStyle),
              if (hasGuild)
                _buildTabTile(context, isMobile, 'Guild Chat', const GuildChatPanel(), tileTitleStyle),

              const SizedBox(height: 12),
              Text('⚙️ Settings', style: sectionHeaderStyle),
              _buildTabTile(context, isMobile, 'Settings', const SettingsScreen(), tileTitleStyle),
              const Divider(),
              ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                leading: const Icon(Icons.logout),
                title: Text('Logout', style: tileTitleStyle),
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
          ),
        ),
      ),
    );
  }

  Widget _buildTabTile(
      BuildContext context,
      bool isMobile,
      String title,
      Widget content, [
        TextStyle? titleStyle,
      ]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        dense: true,
        visualDensity: VisualDensity.compact,
        leading: const Icon(Icons.arrow_right),
        title: Text(title, style: titleStyle),
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
