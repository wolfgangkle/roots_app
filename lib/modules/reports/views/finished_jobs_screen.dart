import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:roots_app/screens/helpers/layout_helper.dart';
import 'package:rxdart/rxdart.dart';

class FinishedJobsScreen extends StatelessWidget {
  const FinishedJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text("Not logged in."));
    }

    final screenSize = LayoutHelper.getSizeCategory(MediaQuery.of(context).size.width);
    final isMobile = screenSize == ScreenSizeCategory.small;

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

        // Collect all streams of /eventReports from each village
        final streams = villageDocs.map((villageDoc) {
          return villageDoc.reference
              .collection('eventReports')
              .orderBy('createdAt', descending: true)
              .snapshots();
        }).toList();

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
              final hiddenList = List<String>.from(data['hiddenForUserIds'] ?? []);
              final type = data['type'] ?? 'unknown';
              return !hiddenList.contains(user.uid) &&
                  (type == 'upgrade' || type == 'crafting');
            })
                .toList();

            allDocs.sort((a, b) {
              final timeA = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
              final timeB = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
              return timeB.compareTo(timeA);
            });

            if (allDocs.isEmpty) {
              return const Center(child: Text("No finished jobs found."));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: allDocs.length,
              itemBuilder: (context, index) {
                final doc = allDocs[index];
                final data = doc.data() as Map<String, dynamic>;
                final type = data['type'] ?? 'unknown';
                final title = data['title'] ?? 'Finished Job';
                final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                final formattedTime =
                createdAt != null ? _formatDate(createdAt) : 'No date';
                final isRead = data['read'] == true;

                return Card(
                  child: ListTile(
                    leading: Icon(_iconForType(type)),
                    title: Text(
                      title,
                      style: TextStyle(
                        fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(formattedTime),
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check_circle_outline),
                          tooltip: "Mark as read",
                          onPressed: () async {
                            await doc.reference.update({'read': true});
                          },
                        ),
                        _reportMenu(user.uid, doc),
                      ],
                    ),
                    onLongPress: () async {
                      await doc.reference.update({'read': !isRead});
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
