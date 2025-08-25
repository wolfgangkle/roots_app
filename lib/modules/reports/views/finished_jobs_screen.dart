// lib/screens/reports/finished_jobs_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';
import 'package:provider/provider.dart';

import 'package:roots_app/theme/app_style_manager.dart';
import 'package:roots_app/theme/widgets/token_panels.dart';
import 'package:roots_app/theme/tokens.dart'; // 👈 brings in SurfaceMode, token types

class FinishedJobsScreen extends StatelessWidget {
  const FinishedJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text("Not logged in."));
    }

    final style = context.watch<StyleManager>().currentStyle;
    final text = style.textOnGlass;

    final villagesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('villages');

    return FutureBuilder<QuerySnapshot>(
      future: villagesRef.get(),
      builder: (context, villageSnapshot) {
        if (!villageSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final villageDocs = villageSnapshot.data!.docs;
        if (villageDocs.isEmpty) {
          return const Center(child: Text("No villages found."));
        }

        // Collect all streams of /finishedJobs from each village
        final streams = villageDocs
            .map((villageDoc) => villageDoc.reference
            .collection('finishedJobs')
            .orderBy('createdAt', descending: true)
            .snapshots())
            .toList();

        return StreamBuilder<List<QuerySnapshot>>(
          stream: CombineLatestStream.list(streams),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final allDocs = snapshot.data!
                .expand((qs) => qs.docs)
                .where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final hiddenList =
              List<String>.from(data['hiddenForUserIds'] ?? []);
              final type = data['type'] ?? 'unknown';
              return !hiddenList.contains(user.uid) &&
                  (type == 'upgrade' || type == 'crafting');
            })
                .toList();

            allDocs.sort((a, b) {
              final timeA =
                  (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
              final timeB =
                  (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
              return timeB.compareTo(timeA);
            });

            if (allDocs.isEmpty) {
              return const Center(child: Text("No finished jobs found."));
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              itemCount: allDocs.length,
              itemBuilder: (context, index) {
                final doc = allDocs[index];
                final data = doc.data() as Map<String, dynamic>;
                final type = (data['type'] ?? 'unknown').toString();
                final title = (data['title'] ?? 'Finished Job').toString();
                final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                final formattedTime =
                createdAt != null ? _formatDate(createdAt) : 'No date';
                final isRead = data['read'] == true;

                final icon = _iconForType(type);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onLongPress: () async {
                      await doc.reference.update({'read': !isRead});
                    },
                    child: TokenPanel(
                      glass: style.glass,
                      text: text,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      borderRadius: style.radius.card.toDouble(),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(icon, color: text.secondary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title
                                Text(
                                  title,
                                  style: TextStyle(
                                    color: text.primary,
                                    fontWeight:
                                    isRead ? FontWeight.w500 : FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Date
                                Text(
                                  formattedTime,
                                  style: TextStyle(
                                    color: text.subtle,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Actions
                          Wrap(
                            spacing: 4,
                            children: [
                              IconButton(
                                tooltip: "Mark as read",
                                onPressed: () async {
                                  await doc.reference.update({'read': true});
                                },
                                icon: Icon(
                                  Icons.check_circle_outline,
                                  color: text.secondary,
                                ),
                              ),
                              _reportMenu(context, user.uid, doc, text),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _reportMenu(
      BuildContext context, String userId, DocumentSnapshot doc, dynamic text) {
    // tokenized popup menu (matches AllianceMembersScreen)
    final style = context.read<StyleManager>().currentStyle;
    final glass = style.glass;
    final tokens = style.textOnGlass;

    final double fillAlpha = glass.mode == SurfaceMode.solid
        ? 1.0
        : (glass.opacity <= 0.02 ? 0.06 : glass.opacity);

    final Color menuBg = glass.baseColor.withValues(alpha: fillAlpha);
    final ShapeBorder menuShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: glass.showBorder
          ? BorderSide(
        color: (glass.borderColor ??
            tokens.subtle.withValues(alpha: glass.strokeOpacity))
            .withValues(alpha: 0.6),
        width: 1,
      )
          : BorderSide.none,
    );

    final popupTheme = PopupMenuThemeData(
      color: menuBg,
      surfaceTintColor: Colors.transparent,
      elevation:
      glass.mode == SurfaceMode.solid && glass.elevation > 0 ? 1.0 : 0.0,
      shape: menuShape,
      textStyle: TextStyle(color: tokens.primary, fontSize: 14),
    );

    return Theme(
      data: Theme.of(context).copyWith(popupMenuTheme: popupTheme),
      child: PopupMenuButton<String>(
        icon: Icon(Icons.more_vert, color: tokens.primary),
        onSelected: (value) async {
          if (value == 'hide') {
            await doc.reference.update({
              'hiddenForUserIds': FieldValue.arrayUnion([userId])
            });
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'hide',
            child: Text(
              'Hide from my view',
              style: TextStyle(color: tokens.primary),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'upgrade':
        return Icons.upgrade;
      case 'crafting':
        return Icons.construction;
      default:
        return Icons.check_circle_outline;
    }
  }

  String _formatDate(DateTime dt) {
    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} – ${dt.day}.${dt.month}.${dt.year}";
  }
}
