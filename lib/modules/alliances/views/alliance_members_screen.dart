import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:roots_app/modules/profile/models/user_profile_model.dart';
import 'package:roots_app/screens/controllers/main_content_controller.dart';
import 'package:roots_app/modules/alliances/views/invite_guild_to_alliance_screen.dart';

import 'package:roots_app/theme/app_style_manager.dart';
import 'package:roots_app/theme/tokens.dart';
import 'package:roots_app/theme/widgets/token_panels.dart';
import 'package:roots_app/theme/widgets/token_buttons.dart'; // <-- NEW

class AllianceMembersScreen extends StatelessWidget {
  const AllianceMembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<UserProfileModel>();
    final allianceId = profile.allianceId;
    final isGuildLeader = profile.guildRole == 'leader';
    final isAllianceLeader = profile.allianceRole == 'leader';

    final style   = context.watch<StyleManager>().currentStyle;
    final glass   = style.glass;
    final text    = style.textOnGlass;
    final buttons = style.buttons; // <-- theme button tokens

    if (allianceId == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: Text("Alliance", style: TextStyle(color: text.primary)),
          iconTheme: IconThemeData(color: text.primary),
        ),
        body: ListView(
          padding: EdgeInsets.fromLTRB(16, kToolbarHeight + 16, 16, 16),
          children: [
            TokenPanel(
              glass: glass,
              text: text,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  "You are not in an alliance.",
                  style: TextStyle(color: text.secondary),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final allianceRef =
    FirebaseFirestore.instance.collection('alliances').doc(allianceId);

    return FutureBuilder<DocumentSnapshot>(
      future: allianceRef.get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator()),
          );
        }

        final alliance = snapshot.data!.data() as Map<String, dynamic>?;
        if (alliance == null) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              title: Text("Alliance", style: TextStyle(color: text.primary)),
              iconTheme: IconThemeData(color: text.primary),
            ),
            body: ListView(
              padding: EdgeInsets.fromLTRB(16, kToolbarHeight + 16, 16, 16),
              children: [
                TokenPanel(
                  glass: glass,
                  text: text,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      "Alliance data not found.",
                      style: TextStyle(color: text.secondary),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final tag = alliance['tag'] ?? '???';
        final name = alliance['name'] ?? 'Unknown Alliance';
        final desc = alliance['description'] as String?;
        final guildIds = List<String>.from(alliance['guildIds'] ?? []);

        return Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            title: Text('[$tag] $name', style: TextStyle(color: text.primary)),
            iconTheme: IconThemeData(color: text.primary),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header panel (invite + description)
              Padding(
                padding: EdgeInsets.fromLTRB(16, kToolbarHeight + 16, 16, 8),
                child: TokenPanel(
                  glass: glass,
                  text: text,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isAllianceLeader)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TokenIconButton(
                            variant: TokenButtonVariant.primary,
                            glass: glass,
                            text: text,
                            buttons: buttons, // <-- themed size/colors/radius
                            onPressed: () {
                              final isMobile = MediaQuery.of(context).size.width < 600;
                              if (isMobile) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const InviteGuildToAllianceScreen(),
                                  ),
                                );
                              } else {
                                final controller = Provider.of<MainContentController>(context, listen: false);
                                controller.setCustomContent(const InviteGuildToAllianceScreen());
                              }
                            },
                            icon: const Icon(Icons.group_add),
                            label: const Text("Invite Guild"),
                          ),
                        ),
                      if (desc != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          desc,
                          style: TextStyle(color: text.secondary, fontSize: 14),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Members list panel
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: FutureBuilder<List<DocumentSnapshot>>(
                    future: _fetchGuilds(guildIds),
                    builder: (context, guildSnap) {
                      if (!guildSnap.hasData) {
                        return const Center(
                          child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator()),
                        );
                      }
                      final docs = guildSnap.data!;
                      final currentGuildId = profile.guildId;

                      return ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data = docs[index].data() as Map<String, dynamic>;
                          final gId = docs[index].id;
                          final gTag = data['tag'] ?? '???';
                          final gName = data['name'] ?? 'Unknown';
                          final isCurrentGuild = gId == currentGuildId;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TokenPanel(
                              glass: glass,
                              text: text,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                child: Row(
                                  children: [
                                    const Icon(Icons.shield),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '[$gTag] $gName',
                                            style: TextStyle(
                                              color: text.primary,
                                              fontWeight: isCurrentGuild ? FontWeight.w700 : FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                          if (isCurrentGuild)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 2),
                                              child: Text(
                                                'Your Guild',
                                                style: TextStyle(color: text.subtle, fontSize: 12),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (isCurrentGuild && isGuildLeader)
                                      _LeaderMenuButton(
                                        isAllianceLeader: isAllianceLeader,
                                        onLeaveOrDisband: (disband) => _handleLeaveOrDisband(context, disband),
                                        glass: glass,
                                        text: text,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<List<DocumentSnapshot>> _fetchGuilds(List<String> guildIds) async {
    if (guildIds.isEmpty) return [];
    final futures = guildIds.map((id) => FirebaseFirestore.instance.doc('guilds/$id').get());
    return await Future.wait(futures);
  }

  Future<void> _handleLeaveOrDisband(BuildContext context, bool disband) async {
    final style   = context.read<StyleManager>().currentStyle;
    final glass   = style.glass;
    final text    = style.textOnGlass;
    final buttons = style.buttons; // <-- themed buttons
    final outlinePalette = ButtonPalette(outlineBorder: buttons.primaryBg);

    bool isProcessing = false;

    await showDialog<bool>(
      context: context,
      barrierDismissible: !isProcessing,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: glass.baseColor.withValues(
                alpha: glass.mode == SurfaceMode.solid
                    ? 1.0
                    : (glass.opacity <= 0.02 ? 0.06 : glass.opacity),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                disband ? 'Disband Alliance?' : 'Leave Alliance?',
                style: TextStyle(color: text.primary),
              ),
              content: Text(
                disband
                    ? 'This will permanently disband the alliance for all member guilds.'
                    : 'Are you sure your guild wants to leave the alliance?',
                style: TextStyle(color: text.secondary),
              ),
              actions: [
                // Cancel -> outline text button
                TokenTextButton(
                  variant: TokenButtonVariant.outline,
                  glass: glass,
                  text: text,
                  buttons: buttons,
                  palette: outlinePalette,
                  onPressed: isProcessing ? null : () => Navigator.pop(context, false),
                  child: const Text("Cancel"),
                ),
                // Confirm -> danger button with spinner
                TokenButton(
                  variant: TokenButtonVariant.danger,
                  glass: glass,
                  text: text,
                  buttons: buttons,
                  onPressed: isProcessing
                      ? null
                      : () async {
                    setState(() => isProcessing = true);

                    final callable = FirebaseFunctions.instance.httpsCallable(
                      disband ? 'disbandAlliance' : 'leaveAlliance',
                    );

                    try {
                      await callable.call();

                      if (context.mounted) {
                        Navigator.pop(context, true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          buildTokenSnackBar(
                            message: disband ? "Alliance disbanded." : "Guild left alliance.",
                            glass: glass,
                            text: text,
                          ),
                        );

                        final controller = Provider.of<MainContentController>(context, listen: false);
                        controller.setCustomContent(const Placeholder());
                      }
                    } catch (e) {
                      if (context.mounted) {
                        setState(() => isProcessing = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          buildTokenSnackBar(
                            message: "Error: $e",
                            glass: glass,
                            text: text,
                          ),
                        );
                      }
                    }
                  },
                  child: isProcessing
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(text.primary),
                    ),
                  )
                      : Text(disband ? "Disband" : "Leave"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Small popup menu extracted for clarity.
class _LeaderMenuButton extends StatelessWidget {
  final bool isAllianceLeader;
  final ValueChanged<bool> onLeaveOrDisband; // true = disband, false = leave
  final GlassTokens glass;
  final TextOnGlassTokens text;

  const _LeaderMenuButton({
    required this.isAllianceLeader,
    required this.onLeaveOrDisband,
    required this.glass,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    // Glass/solid-aware menu surface
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
        icon: Icon(Icons.more_vert, color: text.primary), // tokenized icon color
        onSelected: (value) => onLeaveOrDisband(value == 'disband'),
        itemBuilder: (context) => [
          PopupMenuItem(
            value: isAllianceLeader ? 'disband' : 'leave',
            child: Text(
              isAllianceLeader ? 'Disband Alliance' : 'Leave Alliance',
              style: TextStyle(color: text.primary), // tokenized item text
            ),
          ),
        ],
      ),
    );
  }
}
