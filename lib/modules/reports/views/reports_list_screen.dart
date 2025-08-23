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

class ReportsListScreen extends StatefulWidget {
  const ReportsListScreen({super.key});

  @override
  State<ReportsListScreen> createState() => _ReportsListScreenState();
}

class _ReportsListScreenState extends State<ReportsListScreen> {
  Future<void>? _preflight;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      // 👉 Preflight .get() calls to force Firestore to emit the index link if missing
      _preflight = _runPreflight(uid);
    }
  }

  Future<void> _runPreflight(String uid) async {
    final combatsQuery = FirebaseFirestore.instance
        .collection('combats')
        .where('participantOwnerIds', arrayContains: uid)
        .orderBy('createdAt', descending: true)
        .limit(1);

    final peacefulQuery = FirebaseFirestore.instance
        .collection('peacefulReports')
        .where('participantOwnerIds', arrayContains: uid)
        .orderBy('createdAt', descending: true)
        .limit(1);

    try {
      await Future.wait([combatsQuery.get(), peacefulQuery.get()]);
    } catch (e, st) {
      // This prints the “Create index” URL in debug logs.
      debugPrint('🔥 Firestore index error (preflight): $e');
      debugPrintStack(stackTrace: st);
      // Let UI continue; StreamBuilders below will also surface errors.
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("Not logged in."));

    final style = context.watch<StyleManager>().currentStyle;
    final text = style.textOnGlass;

    final screenSize =
    LayoutHelper.getSizeCategory(MediaQuery.of(context).size.width);
    final isMobile = screenSize == ScreenSizeCategory.small;

    final combatsStream = FirebaseFirestore.instance
        .collection('combats')
        .where('participantOwnerIds', arrayContains: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();

    final peacefulStream = FirebaseFirestore.instance
        .collection('peacefulReports')
        .where('participantOwnerIds', arrayContains: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();

    return FutureBuilder<void>(
      future: _preflight, // ensures preflight runs once; UI renders regardless
      builder: (_, __) {
        return StreamBuilder<QuerySnapshot>(
          stream: combatsStream,
          builder: (context, combatSnap) {
            if (combatSnap.hasError) {
              return _ErrorPanel(
                textColor: text,
                message:
                'Combats query error:\n${combatSnap.error}\n\nCheck console for a “Create index” link.',
              );
            }
            if (combatSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            return StreamBuilder<QuerySnapshot>(
              stream: peacefulStream,
              builder: (context, peaceSnap) {
                if (peaceSnap.hasError) {
                  return _ErrorPanel(
                    textColor: text,
                    message:
                    'Peaceful reports query error:\n${peaceSnap.error}\n\nCheck console for a “Create index” link.',
                  );
                }
                if (peaceSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final combinedDocs = <Map<String, dynamic>>[];

                if (peaceSnap.hasData) {
                  for (final doc in peaceSnap.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    data['id'] = doc.id;
                    data['type'] = 'peaceful';
                    combinedDocs.add(data);
                  }
                }

                if (combatSnap.hasData) {
                  for (final doc in combatSnap.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    data['id'] = doc.id;
                    data['type'] = 'combat';
                    combinedDocs.add(data);
                  }
                }

                combinedDocs.sort((a, b) {
                  final aTime =
                      (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
                  final bTime =
                      (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
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
                    final createdAt =
                    (data['createdAt'] as Timestamp?)?.toDate();
                    final formattedTime =
                    createdAt != null ? _formatDate(createdAt) : 'No date';

                    final type = (data['type'] as String?) ?? 'unknown';
                    final icon = type == 'combat' ? Icons.gavel : Icons.spa;

                    final title = (data['title'] as String?) ??
                        (type == 'combat'
                            ? 'Combat Encounter'
                            : 'Peaceful Encounter');

                    String subtitle;
                    if (type == 'combat') {
                      final heroes = (data['heroes'] as List?) ?? const [];
                      final names = heroes
                          .whereType<Map>()
                          .map((h) => (h['name'] ?? 'Hero').toString())
                          .toList();
                      subtitle = names.isNotEmpty
                          ? '$formattedTime • ${names.join(', ')}'
                          : '$formattedTime • ${heroes.length} hero(s)';
                    } else {
                      final members = (data['members'] as List?) ?? const [];
                      subtitle = '$formattedTime • ${members.length} hero(s)';
                    }

                    final id = data['id'] as String;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: InkWell(
                        onTap: () => _openDetail(context, isMobile, id, type),
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
                                      title,
                                      style: TextStyle(
                                        color: text.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      subtitle,
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

class _ErrorPanel extends StatelessWidget {
  final dynamic textColor;
  final String message;
  const _ErrorPanel({required this.textColor, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TokenPanel(
        glass: context.read<StyleManager>().currentStyle.glass,
        text: context.read<StyleManager>().currentStyle.textOnGlass,
        padding: const EdgeInsets.all(12),
        borderRadius: context.read<StyleManager>().currentStyle.radius.card.toDouble(),
        child: Text(
          message,
          style: TextStyle(color: textColor.secondary),
        ),
      ),
    );
  }
}
