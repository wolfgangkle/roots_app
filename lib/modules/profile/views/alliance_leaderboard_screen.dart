import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roots_app/modules/profile/views/alliance_profile_screen.dart';
import 'package:roots_app/screens/controllers/main_content_controller.dart';

class AllianceLeaderboardScreen extends StatefulWidget {
  const AllianceLeaderboardScreen({super.key});

  @override
  State<AllianceLeaderboardScreen> createState() => _AllianceLeaderboardScreenState();
}

class _AllianceLeaderboardScreenState extends State<AllianceLeaderboardScreen> {
  @override
  void initState() {
    super.initState();

    FirebaseFirestore.instance
        .collection('alliances')
        .orderBy('points', descending: true)
        .limit(1)
        .get().then((_) {}, onError: (error) {
      debugPrint('[Index Trigger] Alliance leaderboard: $error');
      if (error is FirebaseException) {
        debugPrint('[Missing Index] ➜ ${error.message}');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🌐 Alliance Leaderboard')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('alliances')
            .orderBy('points', descending: true)
            .limit(100)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No alliances have risen to fame yet.'));
          }

          final docs = snapshot.data!.docs;

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final name = data['name'] ?? 'Unnamed Alliance';
              final points = data['points'] ?? 0;
              final rank = index + 1;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blueGrey,
                  child: Text(
                    '$rank',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(name),
                trailing: Text(
                  '$points pts',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                onTap: () {
                  final controller = Provider.of<MainContentController>(context, listen: false);
                  controller.setCustomContent(AllianceProfileScreen(allianceId: doc.id));
                },
              );
            },
          );
        },
      ),
    );
  }
}
