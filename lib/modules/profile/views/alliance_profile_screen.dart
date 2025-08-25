import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:roots_app/modules/profile/views/guild_profile_screen.dart';
import 'package:roots_app/screens/controllers/main_content_controller.dart';

// 🔷 Tokens
import 'package:roots_app/theme/app_style_manager.dart';
import 'package:roots_app/theme/widgets/token_panels.dart';
import 'package:roots_app/theme/widgets/token_buttons.dart';

class AllianceProfileScreen extends StatelessWidget {
  final String allianceId;

  const AllianceProfileScreen({super.key, required this.allianceId});

  @override
  Widget build(BuildContext context) {
    // 🔄 Live tokens
    context.watch<StyleManager>();
    final glass = kStyle.glass;
    final text = kStyle.textOnGlass;
    final pad = kStyle.card.padding;

    final allianceRef = FirebaseFirestore.instance.collection('alliances').doc(allianceId);

    return FutureBuilder<DocumentSnapshot>(
      future: allianceRef.get(),
      builder: (context, allianceSnapshot) {
        if (allianceSnapshot.connectionState == ConnectionState.waiting) {
          return Column(
            children: [
              TokenPanel(
                glass: glass,
                text: text,
                padding: EdgeInsets.fromLTRB(pad.left, 14, pad.right, 14),
                child: Text('🌐 Alliance', style: TextStyle(color: text.primary, fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              const SizedBox(height: 12),
              const Expanded(child: Center(child: CircularProgressIndicator())),
            ],
          );
        }

        if (!allianceSnapshot.hasData || !allianceSnapshot.data!.exists) {
          return Column(
            children: [
              TokenPanel(
                glass: glass,
                text: text,
                padding: EdgeInsets.fromLTRB(pad.left, 14, pad.right, 14),
                child: Text('🌐 Alliance', style: TextStyle(color: text.primary, fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: EdgeInsets.fromLTRB(pad.left, 0, pad.right, pad.bottom),
                child: TokenPanel(
                  glass: glass,
                  text: text,
                  padding: EdgeInsets.fromLTRB(pad.left, 14, pad.right, 14),
                  child: Text('Alliance not found.', style: TextStyle(color: text.secondary)),
                ),
              ),
            ],
          );
        }

        final allianceData = allianceSnapshot.data!.data() as Map<String, dynamic>? ?? {};
        final name = (allianceData['name'] ?? 'Unknown Alliance').toString();
        final tag = (allianceData['tag'] ?? '').toString();
        final description = (allianceData['description'] ?? '').toString();
        final createdAt = (allianceData['createdAt'] as Timestamp?)?.toDate();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 🏷 Header
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
                        'Founded on ${DateFormat('yyyy-MM-dd').format(createdAt)}',
                        style: TextStyle(color: text.subtle),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 🛡️ Guilds section title
            Padding(
              padding: EdgeInsets.fromLTRB(pad.left, 0, pad.right, 0),
              child: TokenPanel(
                glass: glass,
                text: text,
                padding: EdgeInsets.fromLTRB(pad.left, 12, pad.right, 12),
                child: Text(
                  'Guilds in this Alliance',
                  style: TextStyle(color: text.primary, fontWeight: FontWeight.w700),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 📜 Guilds list
            Expanded(
              child: FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('guilds')
                    .where('allianceId', isEqualTo: allianceId)
                    .get(),
                builder: (context, guildSnapshot) {
                  if (guildSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!guildSnapshot.hasData || guildSnapshot.data!.docs.isEmpty) {
                    return Padding(
                      padding: EdgeInsets.fromLTRB(pad.left, 0, pad.right, pad.bottom),
                      child: TokenPanel(
                        glass: glass,
                        text: text,
                        padding: EdgeInsets.fromLTRB(pad.left, 14, pad.right, 14),
                        child: Text('No guilds currently part of this alliance.', style: TextStyle(color: text.secondary)),
                      ),
                    );
                  }

                  final docs = guildSnapshot.data!.docs;
                  final controller = Provider.of<MainContentController>(context, listen: false);

                  return ListView.separated(
                    padding: EdgeInsets.fromLTRB(pad.left, 0, pad.right, pad.bottom),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final map = docs[index].data() as Map<String, dynamic>;
                      final guildId = docs[index].id;
                      final gTag = (map['tag'] ?? '').toString();
                      final gName = (map['name'] ?? 'Unknown').toString();

                      return _GuildRow(
                        label: gTag.isNotEmpty ? '[$gTag] $gName' : gName,
                        onTap: () => controller.setCustomContent(GuildProfileScreen(guildId: guildId)),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GuildRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _GuildRow({required this.label, required this.onTap});

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
                style: TextStyle(
                  color: text.primary,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  decorationColor: text.subtle,
                ),
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
