import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roots_app/modules/profile/views/player_profile_screen.dart';
import 'package:roots_app/screens/controllers/main_content_controller.dart';

class PlayerLeaderboardScreen extends StatelessWidget {
  const PlayerLeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏆 Board of Glory'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collectionGroup('profile')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error loading leaderboard'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No glorious heroes... yet.'));
          }

          final docs = snapshot.data!.docs
              .where((doc) => doc.id == 'main')
              .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final building = data['totalBuildingPoints'] ?? 0;
            final hero = data['totalHeroPoints'] ?? 0;
            final total = building + hero;
            final heroName = data['heroName'] ?? 'Unnamed Hero';
            final userId = doc.reference.parent.parent?.id;

            return {
              'heroName': heroName,
              'totalPoints': total,
              'userId': userId,
            };
          })
              .where((e) => e['userId'] != null) // filter out invalid entries
              .toList();

          docs.sort((a, b) =>
              (b['totalPoints'] as int).compareTo(a['totalPoints'] as int));
          final topDocs = docs.take(100).toList();

          return ListView.separated(
            itemCount: topDocs.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (context, index) {
              final entry = topDocs[index];
              final rank = index + 1;
              final heroName = entry['heroName'];
              final totalPoints = entry['totalPoints'];
              final userId = entry['userId'];

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.deepPurple,
                  child: Text(
                    '$rank',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(heroName),
                trailing: Text(
                  '$totalPoints pts',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                onTap: () {
                  final controller =
                  Provider.of<MainContentController>(context, listen: false);
                  controller.setCustomContent(PlayerProfileScreen(userId: userId));
                },
              );
            },
          );
        },
      ),
    );
  }
}
