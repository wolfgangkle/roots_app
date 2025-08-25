import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:roots_app/modules/profile/views/guild_profile_screen.dart';
import 'package:roots_app/screens/controllers/main_content_controller.dart';

// 🔷 Tokens
import 'package:roots_app/theme/app_style_manager.dart';
import 'package:roots_app/theme/widgets/token_panels.dart';
import 'package:roots_app/theme/tokens.dart';

class GuildLeaderboardScreen extends StatelessWidget {
  const GuildLeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 🔄 Live tokens
    context.watch<StyleManager>();
    final glass = kStyle.glass;
    final text = kStyle.textOnGlass;
    final pad = kStyle.card.padding;

    return Column(
      children: [
        // 🏷 Header
        TokenPanel(
          glass: glass,
          text: text,
          padding: EdgeInsets.fromLTRB(pad.left, 14, pad.right, 14),
          child: Text(
            '🏰 Guild Leaderboard',
            style: TextStyle(color: text.primary, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        const SizedBox(height: 12),

        // 📜 Leaderboard list
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('guilds')
                .orderBy('points', descending: true)
                .limit(100)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Padding(
                  padding: EdgeInsets.fromLTRB(pad.left, 0, pad.right, pad.bottom),
                  child: TokenPanel(
                    glass: glass,
                    text: text,
                    padding: EdgeInsets.fromLTRB(pad.left, 14, pad.right, 14),
                    child: Text('No guilds have proven their glory yet.', style: TextStyle(color: text.secondary)),
                  ),
                );
              }

              final docs = snapshot.data!.docs;

              return ListView.separated(
                padding: EdgeInsets.fromLTRB(pad.left, 0, pad.right, pad.bottom),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? 'Unnamed Guild').toString();
                  final points = (data['points'] ?? 0);
                  final rank = index + 1;

                  return _GuildRow(
                    rank: rank,
                    name: name,
                    points: points,
                    onTap: () {
                      final controller = Provider.of<MainContentController>(context, listen: false);
                      controller.setCustomContent(GuildProfileScreen(guildId: doc.id));
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _GuildRow extends StatelessWidget {
  final int rank;
  final String name;
  final int points;
  final VoidCallback onTap;

  const _GuildRow({
    required this.rank,
    required this.name,
    required this.points,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final glass = kStyle.glass;
    final text = kStyle.textOnGlass;
    final pad = kStyle.card.padding;

    final badgeBg = glass.baseColor.withValues(alpha: glass.mode == SurfaceMode.solid ? 0.18 : 0.14);
    const badgeSize = 36.0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: TokenPanel(
        glass: glass,
        text: text,
        padding: EdgeInsets.fromLTRB(pad.left, 12, pad.right, 12),
        child: Row(
          children: [
            // 🏅 Rank badge
            Container(
              width: badgeSize,
              height: badgeSize,
              decoration: BoxDecoration(
                color: badgeBg,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '$rank',
                style: TextStyle(
                  color: text.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // 🏷 Guild name
            Expanded(
              child: Text(
                name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: text.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),

            // ⭐ Points
            Text(
              '$points pts',
              style: TextStyle(
                color: text.secondary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
