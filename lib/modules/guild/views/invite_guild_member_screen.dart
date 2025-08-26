import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 🔷 Tokens
import 'package:roots_app/theme/app_style_manager.dart';
import 'package:roots_app/theme/tokens.dart';
import 'package:roots_app/theme/widgets/token_panels.dart';
import 'package:roots_app/theme/widgets/token_buttons.dart';

class InviteGuildMemberScreen extends StatefulWidget {
  const InviteGuildMemberScreen({super.key});

  @override
  State<InviteGuildMemberScreen> createState() => _InviteGuildMemberScreenState();
}

class _InviteGuildMemberScreenState extends State<InviteGuildMemberScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;
  bool _inviteInProgress = false;
  List<DocumentSnapshot> _results = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() {
      _isLoading = true;
      _results = [];
    });

    try {
      final query = await FirebaseFirestore.instance
          .collectionGroup('profile')
          .where('heroName', isGreaterThanOrEqualTo: _searchQuery)
          .where('heroName', isLessThanOrEqualTo: '$_searchQuery\uf8ff')
          .limit(20)
          .get();

      if (!mounted) return;
      setState(() {
        _results = query.docs;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendInvite(String toUserId, String heroName) async {
    setState(() => _inviteInProgress = true);

    // ✅ Capture before await (no BuildContext across the gap)
    final messenger = ScaffoldMessenger.of(context);
    final glass = kStyle.glass;
    final text  = kStyle.textOnGlass;

    try {
      final callable = FirebaseFunctions.instance.httpsCallable('sendGuildInvite');
      await callable.call({'toUserId': toUserId});

      messenger.showSnackBar(
        buildTokenSnackBar(message: 'Invitation sent to $heroName!', glass: glass, text: text),
      );
    } catch (e) {
      messenger.showSnackBar(
        buildTokenSnackBar(message: 'Failed to send invite: $e', glass: glass, text: text),
      );
    } finally {
      if (mounted) {
        setState(() => _inviteInProgress = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔄 Live-reactive tokens
    context.watch<StyleManager>();
    final glass   = kStyle.glass;
    final text    = kStyle.textOnGlass;
    final buttons = kStyle.buttons;
    final cardPad = kStyle.card.padding;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text('Invite Player to Guild', style: TextStyle(color: text.primary)),
        iconTheme: IconThemeData(color: text.primary),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, kToolbarHeight + 16, 16, 16),
        children: [
          // Search panel
          TokenPanel(
            glass: glass,
            text: text,
            padding: EdgeInsets.fromLTRB(cardPad.left, 14, cardPad.right, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Search by Hero Name', style: TextStyle(color: text.primary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(color: text.primary),
                        cursorColor: text.primary,
                        decoration: _inputDecoration('Type a hero name…', glass, text),
                        onSubmitted: (_) {
                          setState(() => _searchQuery = _searchController.text.trim());
                          _search();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    TokenIconButton(
                      variant: TokenButtonVariant.primary,
                      glass: glass,
                      text: text,
                      buttons: buttons,
                      onPressed: () {
                        setState(() => _searchQuery = _searchController.text.trim());
                        _search();
                      },
                      icon: const Icon(Icons.search),
                      label: const Text('Search'),
                    ),
                  ],
                ),
                if (_isLoading) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Results panel
          if (_results.isEmpty && !_isLoading)
            TokenPanel(
              glass: glass,
              text: text,
              padding: EdgeInsets.fromLTRB(cardPad.left, 14, cardPad.right, 14),
              child: Text('No results yet. Try searching for a player.', style: TextStyle(color: text.secondary)),
            )
          else
            TokenPanel(
              glass: glass,
              text: text,
              padding: EdgeInsets.fromLTRB(cardPad.left, 6, cardPad.right, 6),
              child: ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: _results.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final doc = _results[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final userId = doc.reference.parent.parent?.id;
                  final heroName = (data['heroName'] ?? 'Unknown').toString();
                  final alreadyInGuild = data['guildId'] != null;

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: glass.showBorder
                          ? Border.all(
                        color: (glass.borderColor ?? text.subtle.withValues(alpha: glass.strokeOpacity))
                            .withValues(alpha: 0.6),
                        width: 1,
                      )
                          : null,
                      color: glass.baseColor.withValues(
                        alpha: glass.mode == SurfaceMode.solid
                            ? 1.0
                            : (glass.opacity <= 0.02 ? 0.06 : glass.opacity),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(heroName, style: TextStyle(color: text.primary, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(
                                alreadyInGuild ? 'Already in a guild' : 'Not in a guild',
                                style: TextStyle(color: text.subtle, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        if (!alreadyInGuild)
                          TokenButton(
                            variant: TokenButtonVariant.primary,
                            glass: glass,
                            text: text,
                            buttons: buttons,
                            onPressed: (_inviteInProgress || userId == null)
                                ? null
                                : () => _sendInvite(userId, heroName),
                            child: _inviteInProgress
                                ? SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(text.primary),
                              ),
                            )
                                : const Text('Invite'),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // Tokenized input decoration helper
  InputDecoration _inputDecoration(String hint, GlassTokens glass, TextOnGlassTokens text) {
    final borderColor = (glass.borderColor ?? text.subtle.withValues(alpha: glass.strokeOpacity));

    final double fillAlpha = glass.mode == SurfaceMode.solid
        ? 1.0
        : (glass.opacity <= 0.02 ? 0.06 : glass.opacity.clamp(0.06, 0.18));

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: text.subtle),
      filled: true,
      fillColor: glass.baseColor.withValues(alpha: fillAlpha),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: glass.showBorder
            ? BorderSide(color: borderColor.withValues(alpha: 0.6), width: 1)
            : BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor.withValues(alpha: 0.9), width: 1.2),
      ),
    );
  }
}
