import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:roots_app/modules/reports/views/report_detail_screen.dart';
import 'package:roots_app/screens/controllers/main_content_controller.dart';
import 'package:provider/provider.dart';


class ReportsListScreen extends StatelessWidget {
  const ReportsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text("Not logged in."));
    }

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

        // Assume only one hero for now (main mage)
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

            final reports = snapshot.data!.docs;

            if (reports.isEmpty) {
              return const Center(child: Text("No reports yet."));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final data = reports[index].data() as Map<String, dynamic>;
                final id = reports[index].id;
                final type = data['type'] ?? 'unknown';
                final title = data['title'] ?? 'Untitled Event';
                final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

                return Card(
                  child: ListTile(
                    leading: Icon(_iconForType(type)),
                    title: Text(title),
                    subtitle: createdAt != null
                        ? Text(_formatDate(createdAt))
                        : const Text('No date'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      final controller = Provider.of<MainContentController>(context, listen: false);
                      controller.setCustomContent(
                        ReportDetailScreen(heroId: heroId, reportId: id),
                      );
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'combat':
        return Icons.sports_martial_arts; // or Icons.flash_on, Icons.security
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
