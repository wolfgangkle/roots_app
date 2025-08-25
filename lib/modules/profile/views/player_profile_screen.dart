import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:roots_app/modules/profile/views/guild_profile_screen.dart';
import 'package:roots_app/modules/profile/views/alliance_profile_screen.dart';
import 'package:roots_app/screens/controllers/main_content_controller.dart';

// 🔷 Tokens
import 'package:roots_app/theme/app_style_manager.dart';
import 'package:roots_app/theme/widgets/token_panels.dart';
import 'package:roots_app/theme/tokens.dart';

class PlayerProfileScreen extends StatelessWidget {
  final String userId;

  const PlayerProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    // 🔄 Live tokens
    context.watch<StyleManager>();
    final glass = kStyle.glass;
    final text = kStyle.textOnGlass;
    final pad = kStyle.card.padding;

    final profileRef = FirebaseFirestore.instance.doc('users/$userId/profile/main');
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return FutureBuilder<DocumentSnapshot>(
      future: profileRef.get(),
      builder: (context, snapshot) {
        // Header skeleton (always shows)
        final header = TokenPanel(
          glass: glass,
          text: text,
          padding: EdgeInsets.fromLTRB(pad.left, 14, pad.right, 14),
          child: Text(
            '🧙 Player',
            style: TextStyle(color: text.primary, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        );

        if (!snapshot.hasData) {
          return Column(
            children: [
              header,
              const SizedBox(height: 12),
              const Expanded(child: Center(child: CircularProgressIndicator())),
            ],
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;

        if (data == null) {
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
                  child: Text("Player profile not found.", style: TextStyle(color: text.secondary)),
                ),
              ),
            ],
          );
        }

        final heroName = (data['heroName'] ?? 'Unnamed Hero').toString();
        final buildingPoints = (data['totalBuildingPoints'] ?? 0) as int;
        final heroPoints = (data['totalHeroPoints'] ?? 0) as int;
        final totalPoints = buildingPoints + heroPoints;

        final guildId = data['guildId'];
        final guildTag = data['guildTag'];
        final allianceId = data['allianceId'];
        final allianceTag = data['allianceTag'];
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

        final controller = Provider.of<MainContentController>(context, listen: false);

        // Badge background using glass token
        final youBg = glass.baseColor.withValues(alpha: glass.mode == SurfaceMode.solid ? 0.22 : 0.18);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 🏷 Header row with tags + name + "You"
            TokenPanel(
              glass: glass,
              text: text,
              padding: EdgeInsets.fromLTRB(pad.left, 14, pad.right, 14),
              child: Row(
                children: [
                  // Alliance tag link
                  if (allianceTag != null && allianceId != null)
                    GestureDetector(
                      onTap: () => controller.setCustomContent(AllianceProfileScreen(allianceId: allianceId)),
                      child: Text(
                        '[$allianceTag] ',
                        style: TextStyle(
                          color: text.secondary,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                          decorationColor: text.subtle,
                        ),
                      ),
                    ),
                  // Guild tag link
                  if (guildTag != null && guildId != null)
                    GestureDetector(
                      onTap: () => controller.setCustomContent(GuildProfileScreen(guildId: guildId)),
                      child: Text(
                        '[$guildTag] ',
                        style: TextStyle(
                          color: text.secondary,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                          decorationColor: text.subtle,
                        ),
                      ),
                    ),
                  // Name (flex)
                  Expanded(
                    child: Text(
                      heroName,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: text.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (userId == currentUserId) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: youBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "You",
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: text.primary),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 📊 Stats panel
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
                      "🎯 $totalPoints pts",
                      style: TextStyle(color: text.primary, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "🏗️ $buildingPoints   ⚔️ $heroPoints",
                      style: TextStyle(color: text.secondary),
                    ),
                    if (createdAt != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        "Joined on ${createdAt.toLocal().toString().split(' ')[0]}",
                        style: TextStyle(color: text.subtle),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
