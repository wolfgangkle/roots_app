import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:roots_app/theme/app_style_manager.dart';
import 'package:provider/provider.dart';
import 'package:roots_app/theme/tokens.dart';
import 'package:roots_app/theme/widgets/token_panels.dart';
import 'package:roots_app/theme/widgets/token_buttons.dart';

class InviteGuildToAllianceScreen extends StatefulWidget {
  const InviteGuildToAllianceScreen({super.key});

  @override
  State<InviteGuildToAllianceScreen> createState() =>
      _InviteGuildToAllianceScreenState();
}

class _InviteGuildToAllianceScreenState
    extends State<InviteGuildToAllianceScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;
  bool _inviteInProgress = false;
  List<Map<String, dynamic>> _guildInfos = [];

  Future<void> _search() async {
    setState(() {
      _isLoading = true;
      _guildInfos = [];
    });

    final query = await FirebaseFirestore.instance
        .collection('guilds')
        .where('name', isGreaterThanOrEqualTo: _searchQuery)
        .where('name', isLessThanOrEqualTo: '$_searchQuery\uf8ff')
        .limit(20)
        .get();

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    DocumentSnapshot? userProfileDoc;
    String? allianceId;

    if (currentUserId != null) {
      userProfileDoc = await FirebaseFirestore.instance
          .doc('users/$currentUserId/profile/main')
          .get();

      final profileData = userProfileDoc.data() as Map<String, dynamic>?;
      final guildId = profileData?['guildId'];

      if (guildId != null) {
        final guildDoc =
        await FirebaseFirestore.instance.doc('guilds/$guildId').get();
        allianceId = guildDoc.data()?['allianceId'];
      }
    }

    final results = await Future.wait(query.docs.map((doc) async {
      final data = doc.data();
      final guildId = doc.id;

      String leaderName = 'Unknown';
      int memberCount = 0;
      bool hasPendingInvite = false;

      try {
        final membersQuery = await FirebaseFirestore.instance
            .collectionGroup('profile')
            .where('guildId', isEqualTo: guildId)
            .get();
        memberCount = membersQuery.size;

        QueryDocumentSnapshot<Map<String, dynamic>>? leaderDoc;
        try {
          leaderDoc = membersQuery.docs.firstWhere(
                (d) => d.data()['guildRole'] == 'leader',
          );
        } catch (_) {
          leaderDoc = null;
        }

        if (leaderDoc != null) {
          leaderName = leaderDoc.data()['heroName'] ?? 'Unknown';
        }

        if (allianceId != null) {
          final inviteDoc = await FirebaseFirestore.instance
              .doc('guilds/$guildId/allianceInvites/$allianceId')
              .get();
          hasPendingInvite = inviteDoc.exists;
        }
      } catch (_) {}

      return {
        'id': guildId,
        'name': data['name'],
        'tag': data['tag'],
        'hasAlliance': data['allianceId'] != null,
        'leaderName': leaderName,
        'memberCount': memberCount,
        'hasPendingInvite': hasPendingInvite,
      };
    }));

    if (mounted) {
      setState(() {
        _guildInfos = results;
        _isLoading = false;
      });
    }
  }

  Future<void> _sendInvite(String guildId, String guildName) async {
    final style = context.read<StyleManager>().currentStyle;
    final glass = style.glass;
    final text = style.textOnGlass;

    setState(() => _inviteInProgress = true);

    try {
      final callable =
      FirebaseFunctions.instance.httpsCallable('sendAllianceInvite');
      await callable.call({'targetGuildId': guildId});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          buildTokenSnackBar(
            message: '✅ Invite sent to "$guildName"!',
            glass: glass,
            text: text,
          ),
        );
        _search();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          buildTokenSnackBar(
            message: 'Failed to send invite: $e',
            glass: glass,
            text: text,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _inviteInProgress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final style   = context.watch<StyleManager>().currentStyle;
    final glass   = style.glass;
    final text    = style.textOnGlass;
    final buttons = style.buttons;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text('Invite Guild to Alliance', style: TextStyle(color: text.primary)),
        iconTheme: IconThemeData(color: text.primary),
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(16, kToolbarHeight + 16, 16, 16),
        child: Column(
          children: [
            // Search panel
            TokenPanel(
              glass: glass,
              text: text,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(color: text.primary),
                        decoration: _inputDecoration(
                          context,
                          hint: 'Search guild by name',
                          glass: glass,
                          text: text,
                        ).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(Icons.search, color: text.primary),
                            onPressed: () {
                              setState(() => _searchQuery = _searchController.text.trim());
                              _search();
                            },
                          ),
                        ),
                        onSubmitted: (_) {
                          setState(() => _searchQuery = _searchController.text.trim());
                          _search();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            if (_isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: LinearProgressIndicator(
                  minHeight: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(text.primary),
                  backgroundColor: glass.baseColor.withValues(alpha: 0.25),
                ),
              ),

            const SizedBox(height: 12),

            // Results list
            Expanded(
              child: ListView.builder(
                itemCount: _guildInfos.length,
                itemBuilder: (context, index) {
                  final info = _guildInfos[index];

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
                                    '[${info['tag']}] ${info['name']}',
                                    style: TextStyle(
                                      color: text.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    info['hasAlliance']
                                        ? 'Already in an alliance'
                                        : 'Leader: ${info['leaderName']} • Members: ${info['memberCount']}',
                                    style: TextStyle(
                                      color: text.subtle,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Right: actions
                            if (info['hasAlliance'])
                              Text('In alliance', style: TextStyle(color: text.subtle, fontSize: 12))
                            else if (info['hasPendingInvite'])
                              Text('Pending', style: TextStyle(color: text.subtle, fontSize: 12))
                            else
                              TokenButton(
                                variant: TokenButtonVariant.primary,
                                glass: glass,
                                text: text,
                                buttons: buttons, // theme-dependent size/colors/radius
                                onPressed: _inviteInProgress
                                    ? null
                                    : () => _sendInvite(info['id'], info['name']),
                                child: _inviteInProgress
                                    ? SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(text.primary),
                                  ),
                                )
                                    : const Text('Invite'),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tokenized input decoration (local helper).
InputDecoration _inputDecoration(
    BuildContext context, {
      required String hint,
      required GlassTokens glass,
      required TextOnGlassTokens text,
    }) {
  final fillAlpha = glass.mode == SurfaceMode.solid
      ? 1.0
      : (glass.opacity <= 0.02 ? 0.06 : glass.opacity * 0.5);

  final baseBorderColor =
      glass.borderColor ?? text.subtle.withValues(alpha: glass.strokeOpacity);

  OutlineInputBorder border([double width = 1.0]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: baseBorderColor, width: width),
  );

  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: text.subtle),
    counterStyle: TextStyle(color: text.subtle),
    filled: true,
    fillColor: glass.baseColor.withValues(alpha: fillAlpha),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    enabledBorder: border(),
    focusedBorder: border(1.2),
    disabledBorder: border(),
    errorBorder: border(1.0),
    focusedErrorBorder: border(1.2),
  );
}
