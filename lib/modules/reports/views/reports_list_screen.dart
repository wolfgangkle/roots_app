import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:roots_app/modules/reports/views/report_detail_screen.dart';
import 'package:roots_app/screens/controllers/main_content_controller.dart';
import 'package:roots_app/screens/helpers/layout_helper.dart';
import 'package:provider/provider.dart';

class ReportsListScreen extends StatelessWidget {
  const ReportsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text("Not logged in."));
    }

    final screenSize = LayoutHelper.getSizeCategory(MediaQuery.of(context).size.width);
    final isMobile = screenSize == ScreenSizeCategory.small;

    final reportsRef = FirebaseFirestore.instance
        .collection('heroes')
        .where('ownerId', isEqualTo: user.uid);

    return FutureBuilder<QuerySnapshot>(
      future: reportsRef.get(),
      builder: (context, heroSnapshot) {
        if (!heroSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final heroDocs = heroSnapshot.data!.docs;
        if (heroDocs.isEmpty) {
          return const Center(child: Text("No heroes found."));
        }

        final heroId = heroDocs.first.id;

        final reportStream = FirebaseFirestore.instance
            .collection('heroes')
            .doc(heroId)
            .collection('eventReports')
            .orderBy('createdAt', descending: true)
            .snapshots();

        return StreamBuilder<QuerySnapshot>(
          stream: reportStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final userId = user.uid;
            final allDocs = snapshot.data!.docs;

            final visibleReports = allDocs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final hiddenList = List<String>.from(data['hiddenForUserIds'] ?? []);
              final type = data['type'] ?? 'unknown';
              if (type == 'combat_xp') return false;
              return !hiddenList.contains(userId);
            }).toList();

            if (visibleReports.isEmpty) {
              return const Center(child: Text("No visible reports."));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: visibleReports.length,
              itemBuilder: (context, index) {
                final doc = visibleReports[index];
                final data = doc.data() as Map<String, dynamic>;
                final id = doc.id;
                final type = data['type'] ?? 'unknown';
                final title = data['title'] ?? 'Untitled Event';
                final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                final formattedTime = createdAt != null ? _formatDate(createdAt) : 'No date';
                final isCombat = type == 'combat';

                return Card(
                  child: isCombat && data['combatId'] != null
                      ? FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('combats')
                        .doc(data['combatId'])
                        .get(),
                    builder: (context, combatSnapshot) {
                      final combatData = combatSnapshot.data?.data() as Map<String, dynamic>?;
                      final combatState = combatData?['state'] ?? 'unknown';
                      final isOngoing = combatState == 'ongoing';
                      final subtitle = isOngoing
                          ? "$formattedTime • Ongoing"
                          : "$formattedTime • Completed";

                      return ListTile(
                        leading: Icon(_iconForType(type)),
                        title: Text(title),
                        subtitle: Text(subtitle),
                        trailing: _reportMenu(userId, doc),
                        onTap: () => _openDetail(context, isMobile, heroId, id),
                      );
                    },
                  )
                      : ListTile(
                    leading: Icon(_iconForType(type)),
                    title: Text(title),
                    subtitle: Text(formattedTime),
                    trailing: _reportMenu(userId, doc),
                    onTap: () => _openDetail(context, isMobile, heroId, id),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _reportMenu(String userId, DocumentSnapshot doc) {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == 'hide') {
          await doc.reference.update({
            'hiddenForUserIds': FieldValue.arrayUnion([userId])
          });
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'hide',
          child: Text('Hide from my view'),
        ),
      ],
    );
  }

  void _openDetail(BuildContext context, bool isMobile, String heroId, String reportId) {
    final detailScreen = ReportDetailScreen(
      heroId: heroId,
      reportId: reportId,
    );

    if (isMobile) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => detailScreen),
      );
    } else {
      final controller = Provider.of<MainContentController>(context, listen: false);
      controller.setCustomContent(detailScreen);
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'combat':
        return Icons.sports_martial_arts;
      case 'combat_xp':
        return Icons.star;
      case 'peaceful':
        return Icons.spa;
      case 'upgrade':
        return Icons.build;
      default:
        return Icons.info_outline;
    }
  }

  String _formatDate(DateTime dt) {
    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} – ${dt.day}.${dt.month}.${dt.year}";
  }
}
