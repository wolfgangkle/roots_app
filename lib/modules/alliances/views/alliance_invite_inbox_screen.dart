import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:roots_app/modules/profile/models/user_profile_model.dart';
import 'package:roots_app/theme/app_style_manager.dart';
import 'package:roots_app/theme/widgets/token_panels.dart';
import 'package:roots_app/theme/widgets/token_buttons.dart'; // tokenized buttons

class AllianceInviteInboxScreen extends StatefulWidget {
  const AllianceInviteInboxScreen({super.key});

  @override
  State<AllianceInviteInboxScreen> createState() =>
      _AllianceInviteInboxScreenState();
}

class _AllianceInviteInboxScreenState extends State<AllianceInviteInboxScreen> {
  String? _inviteProcessing;

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<UserProfileModel>();
    final guildId = profile.guildId;
    final isLeader = profile.guildRole == 'leader';

    final style   = context.watch<StyleManager>().currentStyle;
    final glass   = style.glass;
    final text    = style.textOnGlass;
    final buttons = style.buttons; // theme button tokens

    // Tie outline borders to the theme’s primary button color
    final outlinePalette = ButtonPalette(outlineBorder: buttons.primaryBg);

    if (!isLeader || guildId == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: Text("Alliance Invitations", style: TextStyle(color: text.primary)),
          iconTheme: IconThemeData(color: text.primary),
        ),
        body: ListView(
          padding: EdgeInsets.fromLTRB(16, kToolbarHeight + 16, 16, 16),
          children: [
            TokenPanel(
              glass: glass,
              text: text,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "Only guild leaders can view alliance invites.",
                  style: TextStyle(color: text.primary, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final invitesQuery = FirebaseFirestore.instance
        .collection('guilds')
        .doc(guildId)
        .collection('allianceInvites');

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text("Alliance Invitations", style: TextStyle(color: text.primary)),
        iconTheme: IconThemeData(color: text.primary),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: invitesQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator()),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return ListView(
              padding: EdgeInsets.fromLTRB(16, kToolbarHeight + 16, 16, 16),
              children: [
                TokenPanel(
                  glass: glass,
                  text: text,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      "No alliance invites found.",
                      style: TextStyle(color: text.secondary),
                    ),
                  ),
                ),
              ],
            );
          }

          final invites = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.fromLTRB(16, kToolbarHeight + 16, 16, 16),
            itemCount: invites.length,
            itemBuilder: (context, index) {
              final doc = invites[index];
              final data = doc.data() as Map<String, dynamic>;
              final allianceId = data['allianceId'];
              final invitedByGuildId = data['invitedByGuildId'];
              final inviteId = doc.id;
              final isProcessing = _inviteProcessing == inviteId;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.doc('alliances/$allianceId').get(),
                  builder: (context, allianceSnap) {
                    final allianceData =
                        allianceSnap.data?.data() as Map<String, dynamic>? ?? {};
                    final allianceName = allianceData['name'] ?? 'Unknown Alliance';
                    final allianceTag = allianceData['tag'] ?? '???';

                    return TokenPanel(
                      glass: glass,
                      text: text,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left: Alliance info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "[$allianceTag] $allianceName",
                                    style: TextStyle(
                                      color: text.primary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  FutureBuilder<DocumentSnapshot>(
                                    future: FirebaseFirestore.instance
                                        .doc('guilds/$invitedByGuildId')
                                        .get(),
                                    builder: (context, guildSnap) {
                                      final guildData = guildSnap.data?.data()
                                      as Map<String, dynamic>? ??
                                          {};
                                      final byTag = guildData['tag'] ?? '???';
                                      final byName = guildData['name'] ?? 'Unknown Guild';
                                      return Text(
                                        "Invited by: [$byTag] $byName",
                                        style: TextStyle(color: text.subtle, fontSize: 12),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),

                            // Right: Actions (tokenized buttons)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Tooltip(
                                  message: "Accept",
                                  child: TokenIconButton(
                                    variant: TokenButtonVariant.primary,
                                    glass: glass,
                                    text: text,
                                    buttons: buttons, // themed backgrounds/FGs + sizing
                                    onPressed: isProcessing
                                        ? null
                                        : () async {
                                      final messenger = ScaffoldMessenger.of(context);
                                      setState(() => _inviteProcessing = inviteId);
                                      try {
                                        await FirebaseFunctions.instance
                                            .httpsCallable('acceptAllianceInvite')
                                            .call({'allianceId': allianceId});

                                        messenger.showSnackBar(
                                          buildTokenSnackBar(
                                            message: "Joined alliance!",
                                            glass: glass,
                                            text: text,
                                          ),
                                        );
                                      } catch (e) {
                                        messenger.showSnackBar(
                                          buildTokenSnackBar(
                                            message: "Error: $e",
                                            glass: glass,
                                            text: text,
                                          ),
                                        );
                                      } finally {
                                        if (mounted) {
                                          setState(() => _inviteProcessing = null);
                                        }
                                      }
                                    },
                                    icon: isProcessing
                                        ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(text.primary),
                                      ),
                                    )
                                        : const Icon(Icons.check),
                                    label: Text(isProcessing ? "Working..." : "Accept"),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Tooltip(
                                  message: "Decline",
                                  child: TokenIconButton(
                                    variant: TokenButtonVariant.outline,
                                    glass: glass,
                                    text: text,
                                    buttons: buttons,
                                    palette: outlinePalette, // themed outline border
                                    onPressed: isProcessing
                                        ? null
                                        : () async {
                                      final messenger = ScaffoldMessenger.of(context);
                                      setState(() => _inviteProcessing = inviteId);
                                      try {
                                        await FirebaseFirestore.instance
                                            .doc('guilds/$guildId/allianceInvites/$inviteId')
                                            .delete();

                                        messenger.showSnackBar(
                                          buildTokenSnackBar(
                                            message: "Invitation declined.",
                                            glass: glass,
                                            text: text,
                                          ),
                                        );
                                      } catch (e) {
                                        messenger.showSnackBar(
                                          buildTokenSnackBar(
                                            message: "Error: $e",
                                            glass: glass,
                                            text: text,
                                          ),
                                        );
                                      } finally {
                                        if (mounted) {
                                          setState(() => _inviteProcessing = null);
                                        }
                                      }
                                    },
                                    icon: const Icon(Icons.close),
                                    label: const Text("Decline"),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
