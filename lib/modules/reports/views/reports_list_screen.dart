// lib/screens/reports/reports_list_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'package:roots_app/modules/reports/views/report_detail_screen.dart';
import 'package:roots_app/screens/controllers/main_content_controller.dart';
import 'package:roots_app/screens/helpers/layout_helper.dart';
import 'package:roots_app/theme/app_style_manager.dart';
import 'package:roots_app/theme/widgets/token_panels.dart';

class ReportsListScreen extends StatelessWidget {
  const ReportsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text("Not logged in."));
    }

    final style = context.watch<StyleManager>().currentStyle;
    final text = style.textOnGlass;

    final screenSize = LayoutHelper.getSizeCategory(MediaQuery.of(context).size.width);
    final isMobile = screenSize == ScreenSizeCategory.small;

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('heroes')
          .where('ownerId', isEqualTo: user.uid)
          .get(),
      builder: (context, heroSnapshot) {
        if (!heroSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final heroDocs = heroSnapshot.data!.docs;
        if (heroDocs.isEmpty) {
          return const Center(child: Text("No heroes found."));
        }

        final groupIds = <String>{};
        final heroNamesByGroup = <String, List<String>>{};
        final futures = <Future<DocumentSnapshot>>[];

        for (final doc in heroDocs) {
          final data = doc.data() as Map<String, dynamic>;
          final groupId = data['groupId'];
          if (groupId is String) {
            groupIds.add(groupId);
            futures.add(FirebaseFirestore.instance.collection('heroGroups').doc(groupId).get());
          }
        }

        return FutureBuilder<List<DocumentSnapshot>>(
          future: Future.wait(futures),
          builder: (context, groupSnapshot) {
            if (!groupSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            for (final groupDoc in groupSnapshot.data!) {
              final groupData = groupDoc.data() as Map<String, dynamic>? ?? {};
              final memberIds = List<String>.from(groupData['members'] ?? []);
              for (final id in memberIds) {
                final matchingHeroes = heroDocs.where((doc) => doc.id == id);
                if (matchingHeroes.isNotEmpty) {
                  final hero = matchingHeroes.first;
                  heroNamesByGroup.putIfAbsent(groupDoc.id, () => []);
                  heroNamesByGroup[groupDoc.id]!
                      .add((hero.data() as Map<String, dynamic>)['name'] ?? 'Unknown');
                }
              }
            }

            final ids = groupIds.toList();

            final peacefulQuery = FirebaseFirestore.instance
                .collection('peacefulReports')
                .where('groupId', whereIn: ids)
                .get();

            final combatQuery = FirebaseFirestore.instance
                .collection('combats')
                .where('groupId', whereIn: ids)
                .get();

            return FutureBuilder<List<QuerySnapshot>>(
              future: Future.wait([peacefulQuery, combatQuery]),
              builder: (context, combinedSnapshot) {
                if (!combinedSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final combinedDocs = <Map<String, dynamic>>[];

                for (final doc in combinedSnapshot.data![0].docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  data['id'] = doc.id;
                  data['type'] = 'peaceful';
                  combinedDocs.add(data);
                }

                for (final doc in combinedSnapshot.data![1].docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  data['id'] = doc.id;
                  data['type'] = 'combat';
                  combinedDocs.add(data);
                }

                combinedDocs.sort((a, b) {
                  final aTime =
                      (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                  final bTime =
                      (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                  return bTime.compareTo(aTime);
                });

                if (combinedDocs.isEmpty) {
                  return const Center(child: Text("No reports found."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                  itemCount: combinedDocs.length,
                  itemBuilder: (context, index) {
                    final data = combinedDocs[index];
                    final groupId = data['groupId'] ?? 'unknown';
                    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                    final formattedTime =
                    createdAt != null ? _formatDate(createdAt) : 'No date';
                    final heroNames =
                        heroNamesByGroup[groupId]?.join(', ') ?? 'Unknown';
                    final type = data['type'] ?? 'unknown';
                    final icon = type == 'combat' ? Icons.gavel : Icons.spa;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: InkWell(
                        onTap: () => _openDetail(context, isMobile, data['id'], type),
                        borderRadius: BorderRadius.circular(12),
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
                                    Text(
                                      data['eventId'] ?? 'Unknown Event ID',
                                      style: TextStyle(
                                        color: text.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$formattedTime • Group: $heroNames',
                                      style: TextStyle(
                                        color: text.subtle,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
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
      },
    );
  }

  void _openDetail(
      BuildContext context, bool isMobile, String reportId, String type) {
    final detailScreen = ReportDetailScreen(reportId: reportId, type: type);

    if (isMobile) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => detailScreen),
      );
    } else {
      final controller =
      Provider.of<MainContentController>(context, listen: false);
      controller.setCustomContent(detailScreen);
    }
  }

  String _formatDate(DateTime dt) {
    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} – ${dt.day}.${dt.month}.${dt.year}";
  }
}
