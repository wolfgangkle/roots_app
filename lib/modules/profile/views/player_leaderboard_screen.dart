import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roots_app/modules/profile/views/player_profile_screen.dart';
import 'package:roots_app/modules/profile/views/guild_profile_screen.dart';
import 'package:roots_app/modules/profile/views/alliance_profile_screen.dart';
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
              'guildTag': data['guildTag'],
              'allianceTag': data['allianceTag'],
              'guildId': data['guildId'],
              'allianceId': data['allianceId'],
            };
          })
              .where((e) => e['userId'] != null)
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
              final guildTag = entry['guildTag'];
              final allianceTag = entry['allianceTag'];
              final guildId = entry['guildId'];
              final allianceId = entry['allianceId'];

              final controller =
              Provider.of<MainContentController>(context, listen: false);

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.deepPurple,
                  child: Text(
                    '$rank',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (allianceTag != null && allianceId != null)
                      GestureDetector(
                        onTap: () {
                          controller.setCustomContent(AllianceProfileScreen(allianceId: allianceId));
                        },
                        child: Text(
                          '[$allianceTag]',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    if (guildTag != null && guildId != null)
                      GestureDetector(
                        onTap: () {
                          controller.setCustomContent(GuildProfileScreen(guildId: guildId));
                        },
                        child: Text(
                          '[$guildTag]',
                          style: const TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    Text(
                      heroName,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),

                trailing: Text(
                  '$totalPoints pts',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                onTap: () {
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
