import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 🔷 Tokens
import 'package:roots_app/theme/app_style_manager.dart';
import 'package:roots_app/theme/widgets/token_panels.dart';
import 'package:roots_app/theme/widgets/token_buttons.dart';

class GuildInviteInboxScreen extends StatefulWidget {
  const GuildInviteInboxScreen({super.key});

  @override
  State<GuildInviteInboxScreen> createState() => _GuildInviteInboxScreenState();
}

class _GuildInviteInboxScreenState extends State<GuildInviteInboxScreen> {
  String? _inviteProcessing;

  @override
  Widget build(BuildContext context) {
    // 🔄 Live-reactive tokens
    context.watch<StyleManager>();
    final glass   = kStyle.glass;
    final text    = kStyle.textOnGlass;
    final cardPad = kStyle.card.padding;

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: Text("Guild Invitations", style: TextStyle(color: text.primary)),
          iconTheme: IconThemeData(color: text.primary),
        ),
        body: Padding(
          padding: EdgeInsets.fromLTRB(16, kToolbarHeight + 16, 16, 16),
          child: TokenPanel(
            glass: glass,
            text: text,
            padding: EdgeInsets.fromLTRB(cardPad.left, 14, cardPad.right, 14),
            child: Text("Not logged in.", style: TextStyle(color: text.secondary)),
          ),
        ),
      );
    }

    final invitesQuery = FirebaseFirestore.instance
        .collection('guildInvites')
        .where('toUserId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending');

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text("Guild Invitations", style: TextStyle(color: text.primary)),
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
                  padding: EdgeInsets.fromLTRB(cardPad.left, 14, cardPad.right, 14),
                  child: Text(
                    "No guild invites found.",
                    style: TextStyle(color: text.secondary),
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
              final guildId      = data['guildId'];
              final fromUserId   = data['fromUserId'];
              final inviteId     = doc.id;
              final isProcessing = _inviteProcessing == inviteId;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.doc('guilds/$guildId').get(),
                  builder: (context, guildSnap) {
                    final guildName = guildSnap.data?.get('name') ?? 'Unknown Guild';
                    final guildTag  = guildSnap.data?.get('tag') ?? '???';

                    return TokenPanel(
                      glass: glass,
                      text: text,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      child: Row(
                        children: [
                          const Icon(Icons.shield),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "[$guildTag] $guildName",
                                  style: TextStyle(
                                    color: text.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Invited by: $fromUserId",
                                  style: TextStyle(color: text.subtle, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          // Actions
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Accept
                              TokenIconButton(
                                variant: TokenButtonVariant.primary,
                                glass: glass,
                                text: text,
                                buttons: kStyle.buttons,
                                onPressed: isProcessing ? null : () => _handleAccept(context, inviteId, guildId),
                                icon: isProcessing
                                    ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(text.primary),
                                  ),
                                )
                                    : const Icon(Icons.check),
                                label: Text(isProcessing ? "Working..." : "Accept"),
                              ),
                              const SizedBox(width: 8),
                              // Decline
                              TokenTextButton
                                (
                                variant: TokenButtonVariant.outline,
                                glass: glass,
                                text: text,
                                buttons: kStyle.buttons,
                                onPressed: isProcessing ? null : () => _handleDecline(context, inviteId),
                                child: const Text("Decline"),
                              ),
                            ],
                          ),
                        ],
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

  Future<void> _handleAccept(BuildContext context, String inviteId, String guildId) async {
    setState(() => _inviteProcessing = inviteId);

    // Pre-grab what we need so we don't use BuildContext after await.
    final messenger = ScaffoldMessenger.of(context);
    final glass = kStyle.glass;
    final text  = kStyle.textOnGlass;

    try {
      await FirebaseFunctions.instance
          .httpsCallable('acceptGuildInvite')
          .call({'guildId': guildId});

      messenger.showSnackBar(
        buildTokenSnackBar(message: "Joined guild!", glass: glass, text: text),
      );
    } catch (e) {
      messenger.showSnackBar(
        buildTokenSnackBar(message: "Error: $e", glass: glass, text: text),
      );
    } finally {
      if (mounted) setState(() => _inviteProcessing = null);
    }
  }

  Future<void> _handleDecline(BuildContext context, String inviteId) async {
    setState(() => _inviteProcessing = inviteId);

    // Pre-grab what we need so we don't use BuildContext after await.
    final messenger = ScaffoldMessenger.of(context);
    final glass = kStyle.glass;
    final text  = kStyle.textOnGlass;

    try {
      await FirebaseFirestore.instance
          .doc('guildInvites/$inviteId')
          .update({'status': 'declined'});

      messenger.showSnackBar(
        buildTokenSnackBar(message: "Invitation declined.", glass: glass, text: text),
      );
    } catch (e) {
      messenger.showSnackBar(
        buildTokenSnackBar(message: "Error: $e", glass: glass, text: text),
      );
    } finally {
      if (mounted) setState(() => _inviteProcessing = null);
    }
  }
}
