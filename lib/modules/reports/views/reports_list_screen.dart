import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:roots_app/modules/reports/views/report_detail_screen.dart';
import 'package:roots_app/screens/controllers/main_content_controller.dart';
import 'package:roots_app/screens/helpers/layout_helper.dart';

class ReportsListScreen extends StatelessWidget {
  const ReportsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text("Not logged in."));
    }

    final screenSize =
    LayoutHelper.getSizeCategory(MediaQuery.of(context).size.width);
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
            futures.add(FirebaseFirestore.instance
                .collection('heroGroups')
                .doc(groupId)
                .get());
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

            final reportQuery = FirebaseFirestore.instance
                .collection('peacefulReports')
                .where('groupId', whereIn: groupIds.toList());

            return FutureBuilder<QuerySnapshot>(
              future: reportQuery.get(),
              builder: (context, reportSnapshot) {
                if (!reportSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final reports = reportSnapshot.data!.docs;
                reports.sort((a, b) {
                  final aTime = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                  final bTime = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                  return bTime.compareTo(aTime);
                });

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final doc = reports[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final groupId = data['groupId'] ?? 'unknown';
                    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                    final formattedTime =
                    createdAt != null ? _formatDate(createdAt) : 'No date';
                    final description = data['description'] ?? 'Unknown event';
                    final heroNames =
                        heroNamesByGroup[groupId]?.join(', ') ?? 'Unknown';

                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.spa),
                        title: Text(data['eventId'] ?? 'Unknown Event ID'),
                        subtitle: Text('$formattedTime • Group: $heroNames'),
                        onTap: () => _openDetail(context, isMobile, doc.id),
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

  void _openDetail(BuildContext context, bool isMobile, String reportId) {
    final detailScreen = ReportDetailScreen(reportId: reportId);

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
