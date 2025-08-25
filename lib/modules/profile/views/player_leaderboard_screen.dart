import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:roots_app/modules/profile/views/player_profile_screen.dart';
import 'package:roots_app/modules/profile/views/guild_profile_screen.dart';
import 'package:roots_app/modules/profile/views/alliance_profile_screen.dart';
import 'package:roots_app/screens/controllers/main_content_controller.dart';

// 🔷 Tokens
import 'package:roots_app/theme/app_style_manager.dart';
import 'package:roots_app/theme/widgets/token_panels.dart';
import 'package:roots_app/theme/tokens.dart';

class PlayerLeaderboardScreen extends StatelessWidget {
  const PlayerLeaderboardScreen({super.key});

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
            '🏆 Board of Glory',
            style: TextStyle(color: text.primary, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        const SizedBox(height: 12),

        // 📜 Leaderboard list
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collectionGroup('profile').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Padding(
                  padding: EdgeInsets.fromLTRB(pad.left, 0, pad.right, pad.bottom),
                  child: TokenPanel(
                    glass: glass,
                    text: text,
                    padding: EdgeInsets.fromLTRB(pad.left, 14, pad.right, 14),
                    child: Text('Error loading leaderboard', style: TextStyle(color: text.secondary)),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Padding(
                  padding: EdgeInsets.fromLTRB(pad.left, 0, pad.right, pad.bottom),
                  child: TokenPanel(
                    glass: glass,
                    text: text,
                    padding: EdgeInsets.fromLTRB(pad.left, 14, pad.right, 14),
                    child: Text('No glorious heroes... yet.', style: TextStyle(color: text.secondary)),
                  ),
                );
              }

              final mapped = snapshot.data!.docs
                  .where((doc) => doc.id == 'main')
                  .map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final building = (data['totalBuildingPoints'] ?? 0) as int;
                final hero = (data['totalHeroPoints'] ?? 0) as int;
                final total = building + hero;
                final heroName = (data['heroName'] ?? 'Unnamed Hero').toString();
                final userId = doc.reference.parent.parent?.id;

                return {
                  'heroName': heroName,
                  'totalPoints': total,
                  'userId': userId,
                  'guildTag': data['guildTag'],
                  'allianceTag': data['allianceTag'],
                  'guildId': data['guildId'],
                  'allianceId': data['allianceId'],
                };
              })
                  .where((e) => e['userId'] != null)
                  .toList();

              mapped.sort((a, b) => (b['totalPoints'] as int).compareTo(a['totalPoints'] as int));
              final topDocs = mapped.take(100).toList();

              return ListView.separated(
                padding: EdgeInsets.fromLTRB(pad.left, 0, pad.right, pad.bottom),
                itemCount: topDocs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final entry = topDocs[index];
                  final rank = index + 1;
                  final heroName = entry['heroName'] as String;
                  final totalPoints = entry['totalPoints'] as int;
                  final userId = entry['userId'] as String;
                  final guildTag = entry['guildTag'];
                  final allianceTag = entry['allianceTag'];
                  final guildId = entry['guildId'];
                  final allianceId = entry['allianceId'];

                  final controller = Provider.of<MainContentController>(context, listen: false);
                  return _PlayerRow(
                    rank: rank,
                    heroName: heroName,
                    totalPoints: totalPoints,
                    guildTag: guildTag?.toString(),
                    allianceTag: allianceTag?.toString(),
                    onTapHero: () => controller.setCustomContent(PlayerProfileScreen(userId: userId)),
                    onTapGuild: (guildId is String)
                        ? () => controller.setCustomContent(GuildProfileScreen(guildId: guildId))
                        : null,
                    onTapAlliance: (allianceId is String)
                        ? () => controller.setCustomContent(AllianceProfileScreen(allianceId: allianceId))
                        : null,
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

class _PlayerRow extends StatelessWidget {
  final int rank;
  final String heroName;
  final int totalPoints;
  final String? guildTag;
  final String? allianceTag;
  final VoidCallback onTapHero;
  final VoidCallback? onTapGuild;
  final VoidCallback? onTapAlliance;

  const _PlayerRow({
    required this.rank,
    required this.heroName,
    required this.totalPoints,
    required this.onTapHero,
    this.guildTag,
    this.allianceTag,
    this.onTapGuild,
    this.onTapAlliance,
  });

  @override
  Widget build(BuildContext context) {
    final glass = kStyle.glass;
    final text = kStyle.textOnGlass;
    final pad = kStyle.card.padding;

    final badgeBg = glass.baseColor.withValues(alpha: glass.mode == SurfaceMode.solid ? 0.18 : 0.14);
    const badgeSize = 36.0;

    return InkWell(
      onTap: onTapHero,
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
              child: Text('$rank', style: TextStyle(color: text.primary, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 12),

            // 🏷 Tags + name
            Expanded(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (allianceTag != null && onTapAlliance != null)
                    GestureDetector(
                      onTap: onTapAlliance,
                      child: Text(
                        '[$allianceTag]',
                        style: TextStyle(
                          color: text.secondary,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: text.subtle,
                        ),
                      ),
                    ),
                  if (guildTag != null && onTapGuild != null)
                    GestureDetector(
                      onTap: onTapGuild,
                      child: Text(
                        '[$guildTag]',
                        style: TextStyle(
                          color: text.secondary,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: text.subtle,
                        ),
                      ),
                    ),
                  Text(
                    heroName,
                    style: TextStyle(color: text.primary, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            // ⭐ Points
            Text(
              '$totalPoints pts',
              style: TextStyle(color: text.secondary, fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
