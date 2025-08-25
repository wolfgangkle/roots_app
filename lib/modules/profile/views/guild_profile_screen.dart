import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:roots_app/modules/profile/views/player_profile_screen.dart';
import 'package:roots_app/screens/controllers/main_content_controller.dart';

// 🔷 Tokens
import 'package:roots_app/theme/app_style_manager.dart';
import 'package:roots_app/theme/widgets/token_panels.dart';
import 'package:roots_app/theme/widgets/token_buttons.dart';

class GuildProfileScreen extends StatefulWidget {
  final String guildId;

  const GuildProfileScreen({super.key, required this.guildId});

  @override
  State<GuildProfileScreen> createState() => _GuildProfileScreenState();
}

class _GuildProfileScreenState extends State<GuildProfileScreen> {
  bool _showMembers = false;

  @override
  Widget build(BuildContext context) {
    // 🔄 Live tokens
    context.watch<StyleManager>();
    final glass = kStyle.glass;
    final text = kStyle.textOnGlass;
    final pad = kStyle.card.padding;

    final guildRef = FirebaseFirestore.instance.collection('guilds').doc(widget.guildId);

    return FutureBuilder<DocumentSnapshot>(
      future: guildRef.get(),
      builder: (context, snapshot) {
        // Header (always shown)
        final header = TokenPanel(
          glass: glass,
          text: text,
          padding: EdgeInsets.fromLTRB(pad.left, 14, pad.right, 14),
          child: Text(
            '🏰 Guild',
            style: TextStyle(color: text.primary, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        );

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            children: [
              header,
              const SizedBox(height: 12),
              const Expanded(child: Center(child: CircularProgressIndicator())),
            ],
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Column(
            children: [
              header,
              const SizedBox(height: 12),
              Padding(
                padding: EdgeInsets.fromLTRB(pad.left, 0, pad.right, pad.bottom),
                child: TokenPanel(
                  glass: glass,
                  text: text,
                  padding: EdgeInsets.fromLTRB(pad.left, 14, pad.right, 14),
                  child: Text("Guild not found.", style: TextStyle(color: text.secondary)),
                ),
              ),
            ],
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final name = (data['name'] ?? 'Unknown').toString();
        final tag = (data['tag'] ?? '').toString();
        final description = (data['description'] ?? '').toString();
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 🏷 Header with name/tag
            TokenPanel(
              glass: glass,
              text: text,
              padding: EdgeInsets.fromLTRB(pad.left, 14, pad.right, 14),
              child: Text(
                tag.isNotEmpty ? '[$tag] $name' : name,
                style: TextStyle(color: text.primary, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            const SizedBox(height: 12),

            // 📝 Description + meta
            Padding(
              padding: EdgeInsets.fromLTRB(pad.left, 0, pad.right, 0),
              child: TokenPanel(
                glass: glass,
                text: text,
                padding: EdgeInsets.fromLTRB(pad.left, 14, pad.right, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      description.isNotEmpty ? description : '(No description set.)',
                      style: TextStyle(color: description.isNotEmpty ? text.secondary : text.subtle),
                    ),
                    if (createdAt != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        "Founded on ${DateFormat('yyyy-MM-dd').format(createdAt)}",
                        style: TextStyle(color: text.subtle),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 👥 Members toggle
            Padding(
              padding: EdgeInsets.fromLTRB(pad.left, 0, pad.right, 0),
              child: TokenPanel(
                glass: glass,
                text: text,
                padding: EdgeInsets.fromLTRB(pad.left, 10, pad.right, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "👥 Members",
                        style: TextStyle(color: text.primary, fontWeight: FontWeight.w700),
                      ),
                    ),
                    TokenTextButton(
                      variant: TokenButtonVariant.ghost,
                      glass: glass,
                      text: text,
                      onPressed: () => setState(() => _showMembers = !_showMembers),
                      child: Text(_showMembers ? "Hide" : "Show", style: TextStyle(color: text.secondary)),
                    ),
                  ],
                ),
              ),
            ),

            // 📜 Members list
            if (_showMembers) ...[
              const SizedBox(height: 8),
              Expanded(
                child: FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collectionGroup('profile')
                      .where('guildId', isEqualTo: widget.guildId)
                      .orderBy('heroName')
                      .get(),
                  builder: (context, membersSnapshot) {
                    if (membersSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = membersSnapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return Padding(
                        padding: EdgeInsets.fromLTRB(pad.left, 0, pad.right, pad.bottom),
                        child: TokenPanel(
                          glass: glass,
                          text: text,
                          padding: EdgeInsets.fromLTRB(pad.left, 14, pad.right, 14),
                          child: Text("No members found.", style: TextStyle(color: text.secondary)),
                        ),
                      );
                    }

                    final controller = Provider.of<MainContentController>(context, listen: false);

                    return ListView.separated(
                      padding: EdgeInsets.fromLTRB(pad.left, 0, pad.right, pad.bottom),
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final profile = docs[index].data() as Map<String, dynamic>;
                        final userId = docs[index].reference.parent.parent?.id;
                        final heroName = (profile['heroName'] ?? 'Unnamed Hero').toString();
                        final gTag = (profile['guildTag'] ?? '').toString();

                        return _MemberRow(
                          label: gTag.isNotEmpty ? '[$gTag] $heroName' : heroName,
                          onTap: () {
                            if (userId != null) {
                              controller.setCustomContent(PlayerProfileScreen(userId: userId));
                            }
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _MemberRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _MemberRow({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final glass = kStyle.glass;
    final text = kStyle.textOnGlass;
    final pad = kStyle.card.padding;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: TokenPanel(
        glass: glass,
        text: text,
        padding: EdgeInsets.fromLTRB(pad.left, 12, pad.right, 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: text.primary, fontWeight: FontWeight.w600),
              ),
            ),
            TokenTextButton(
              variant: TokenButtonVariant.ghost,
              glass: glass,
              text: text,
              onPressed: onTap,
              child: Text('Open', style: TextStyle(color: text.secondary)),
            ),
          ],
        ),
      ),
    );
  }
}
