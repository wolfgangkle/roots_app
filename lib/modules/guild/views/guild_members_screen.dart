import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:roots_app/modules/profile/models/user_profile_model.dart';
import 'package:roots_app/modules/guild/views/invite_guild_member_screen.dart';
import 'package:roots_app/screens/controllers/main_content_controller.dart';

// 🔷 Tokens
import 'package:roots_app/theme/app_style_manager.dart';
import 'package:roots_app/theme/tokens.dart';
import 'package:roots_app/theme/widgets/token_panels.dart';
import 'package:roots_app/theme/widgets/token_buttons.dart';

class GuildMembersScreen extends StatelessWidget {
  const GuildMembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 🔄 Live-reactive tokens
    context.watch<StyleManager>();
    final glass   = kStyle.glass;
    final text    = kStyle.textOnGlass;
    final buttons = kStyle.buttons;
    final cardPad = kStyle.card.padding;

    final profile  = context.watch<UserProfileModel>();
    final guildId  = profile.guildId;
    final userRole = profile.guildRole;

    if (guildId == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: Text('Guild Members', style: TextStyle(color: text.primary)),
          iconTheme: IconThemeData(color: text.primary),
        ),
        body: Padding(
          padding: EdgeInsets.fromLTRB(16, kToolbarHeight + 16, 16, 16),
          child: TokenPanel(
            glass: glass,
            text: text,
            padding: EdgeInsets.fromLTRB(cardPad.left, 14, cardPad.right, 14),
            child: Text("You are not in a guild.", style: TextStyle(color: text.secondary)),
          ),
        ),
      );
    }

    final isLeader  = userRole == 'leader';
    final isOfficer = userRole == 'officer';

    final query = FirebaseFirestore.instance
        .collectionGroup('profile')
        .where('guildId', isEqualTo: guildId);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text('Guild Members', style: TextStyle(color: text.primary)),
        iconTheme: IconThemeData(color: text.primary),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isLeader || isOfficer)
            Padding(
              padding: EdgeInsets.fromLTRB(16, kToolbarHeight + 16, 16, 8),
              child: TokenIconButton(
                variant: TokenButtonVariant.primary,
                glass: glass,
                text: text,
                buttons: buttons,
                onPressed: () {
                  final isMobile = MediaQuery.of(context).size.width < 600;
                  if (isMobile) {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const InviteGuildMemberScreen()),
                    );
                  } else {
                    final controller = Provider.of<MainContentController>(context, listen: false);
                    controller.setCustomContent(const InviteGuildMemberScreen());
                  }
                },
                icon: const Icon(Icons.person_add),
                label: const Text("Invite Member"),
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: TokenPanel(
                      glass: glass,
                      text: text,
                      padding: EdgeInsets.fromLTRB(cardPad.left, 14, cardPad.right, 14),
                      child: Text(
                        "Error loading guild members:\n${snapshot.error}",
                        style: TextStyle(color: text.secondary),
                      ),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                final currentUserId = FirebaseAuth.instance.currentUser?.uid;

                if (docs.isEmpty) {
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    children: [
                      TokenPanel(
                        glass: glass,
                        text: text,
                        padding: EdgeInsets.fromLTRB(cardPad.left, 14, cardPad.right, 14),
                        child: Text("No members found.", style: TextStyle(color: text.secondary)),
                      ),
                    ],
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final heroName = (data['heroName'] ?? 'Unknown').toString();
                    final role     = (data['guildRole'] ?? 'member').toString();
                    final userId   = docs[index].reference.parent.parent?.id;
                    final isYou    = userId == currentUserId;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TokenPanel(
                        glass: glass,
                        text: text,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        child: Row(
                          children: [
                            Icon(
                              role == 'leader'
                                  ? Icons.verified
                                  : role == 'officer'
                                  ? Icons.star
                                  : Icons.person,
                              color: text.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isYou ? "$heroName (You)" : heroName,
                                    style: TextStyle(
                                      color: text.primary,
                                      fontWeight: isYou ? FontWeight.w700 : FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    role,
                                    style: TextStyle(color: text.subtle, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            if (isYou && role != 'leader')
                              _LeaveGuildMenu(glass: glass, text: text)
                            else if (!isYou && (isLeader || (isOfficer && role != 'leader')))
                              _RoleActionsMenu(
                                userId: userId!,
                                currentRole: role,
                                isLeader: isLeader,
                                glass: glass,
                                text: text,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaveGuildMenu extends StatelessWidget {
  final GlassTokens glass;
  final TextOnGlassTokens text;

  const _LeaveGuildMenu({required this.glass, required this.text});

  @override
  Widget build(BuildContext context) {
    // Tokenized popup menu surface
    final double fillAlpha = glass.mode == SurfaceMode.solid
        ? 1.0
        : (glass.opacity <= 0.02 ? 0.06 : glass.opacity);
    final Color menuBg = glass.baseColor.withValues(alpha: fillAlpha);
    final ShapeBorder menuShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: glass.showBorder
          ? BorderSide(
        color: (glass.borderColor ?? text.subtle.withValues(alpha: glass.strokeOpacity))
            .withValues(alpha: 0.6),
        width: 1,
      )
          : BorderSide.none,
    );

    final popupTheme = PopupMenuThemeData(
      color: menuBg,
      surfaceTintColor: Colors.transparent,
      elevation: glass.mode == SurfaceMode.solid && glass.elevation > 0 ? 1.0 : 0.0,
      shape: menuShape,
      textStyle: TextStyle(color: text.primary, fontSize: 14),
    );

    return Theme(
      data: Theme.of(context).copyWith(popupMenuTheme: popupTheme),
      child: PopupMenuButton<String>(
        icon: Icon(Icons.more_vert, color: text.primary),
        onSelected: (value) async {
          if (value != 'leave') return;

          // Pre-grab messenger to avoid BuildContext after await
          final messenger = ScaffoldMessenger.of(context);

          final confirmed = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              backgroundColor: menuBg,
              shape: menuShape,
              title: Text('Leave Guild?', style: TextStyle(color: text.primary)),
              content: Text(
                'Are you sure you want to leave the guild? This cannot be undone.',
                style: TextStyle(color: text.secondary),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text("Cancel", style: TextStyle(color: text.primary)),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text("Leave", style: TextStyle(color: text.primary)),
                ),
              ],
            ),
          );

          if (confirmed != true) return;

          try {
            await FirebaseFunctions.instance.httpsCallable('leaveGuild').call();
            messenger.showSnackBar(
              buildTokenSnackBar(message: 'You left the guild.', glass: glass, text: text),
            );
          } catch (e) {
            messenger.showSnackBar(
              buildTokenSnackBar(message: 'Error: $e', glass: glass, text: text),
            );
          }
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: 'leave', child: Text('Leave Guild')),
        ],
      ),
    );
  }
}

class _RoleActionsMenu extends StatelessWidget {
  final String userId;
  final String currentRole;
  final bool isLeader;
  final GlassTokens glass;
  final TextOnGlassTokens text;

  const _RoleActionsMenu({
    required this.userId,
    required this.currentRole,
    required this.isLeader,
    required this.glass,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    // Tokenized popup styling
    final double fillAlpha = glass.mode == SurfaceMode.solid
        ? 1.0
        : (glass.opacity <= 0.02 ? 0.06 : glass.opacity);
    final Color menuBg = glass.baseColor.withValues(alpha: fillAlpha);
    final ShapeBorder menuShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: glass.showBorder
          ? BorderSide(
        color: (glass.borderColor ?? text.subtle.withValues(alpha: glass.strokeOpacity))
            .withValues(alpha: 0.6),
        width: 1,
      )
          : BorderSide.none,
    );

    final popupTheme = PopupMenuThemeData(
      color: menuBg,
      surfaceTintColor: Colors.transparent,
      elevation: glass.mode == SurfaceMode.solid && glass.elevation > 0 ? 1.0 : 0.0,
      shape: menuShape,
      textStyle: TextStyle(color: text.primary, fontSize: 14),
    );

    return Theme(
      data: Theme.of(context).copyWith(popupMenuTheme: popupTheme),
      child: PopupMenuButton<String>(
        icon: Icon(Icons.more_vert, color: text.primary),
        onSelected: (value) async {
          final messenger = ScaffoldMessenger.of(context);

          final confirm = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              backgroundColor: menuBg,
              shape: menuShape,
              title: Text("Are you sure?", style: TextStyle(color: text.primary)),
              content: Text("This will change the member's role.", style: TextStyle(color: text.secondary)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text("Cancel", style: TextStyle(color: text.primary)),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text("Confirm", style: TextStyle(color: text.primary)),
                ),
              ],
            ),
          );

          if (confirm != true) return;

          String? newRole;
          if (value == 'promote') {
            newRole = 'officer';
          } else if (value == 'demote') {
            newRole = 'member';
          } else if (value == 'kick') {
            newRole = null;
          }

          try {
            final callable = FirebaseFunctions.instance.httpsCallable('updateGuildRole');
            await callable.call({
              'targetUserId': userId,
              'newRole': newRole,
            });

            messenger.showSnackBar(
              buildTokenSnackBar(
                message: newRole == null ? "Member kicked." : "Role updated.",
                glass: glass,
                text: text,
              ),
            );
          } catch (e) {
            messenger.showSnackBar(
              buildTokenSnackBar(message: "Error: $e", glass: glass, text: text),
            );
          }
        },
        itemBuilder: (context) {
          return [
            if (currentRole == 'member')
              const PopupMenuItem(value: 'promote', child: Text('Promote to Officer')),
            if (currentRole == 'officer')
              const PopupMenuItem(value: 'demote', child: Text('Demote to Member')),
            if (isLeader)
              const PopupMenuItem(value: 'kick', child: Text('Kick from Guild')),
          ];
        },
      ),
    );
  }
}
