import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:roots_app/modules/profile/views/guild_profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:roots_app/screens/controllers/main_content_controller.dart';

class PlayerProfileScreen extends StatelessWidget {
  final String userId;

  const PlayerProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final profileRef = FirebaseFirestore.instance.doc('users/$userId/profile/main');
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('👤 Hero Profile')),
      body: FutureBuilder<DocumentSnapshot>(
        future: profileRef.get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;

          if (data == null) {
            return const Center(child: Text("Player profile not found."));
          }

          final heroName = data['heroName'] ?? 'Unnamed Hero';
          final buildingPoints = data['totalBuildingPoints'] ?? 0;
          final heroPoints = data['totalHeroPoints'] ?? 0;
          final totalPoints = buildingPoints + heroPoints;
          final guildId = data['guildId'];
          final guildTag = data['guildTag'] ?? '';
          final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      heroName,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(width: 8),
                    if (userId == currentUserId)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "You",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text("🎯 $totalPoints pts",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text("🏗️ $buildingPoints   ⚔️ $heroPoints",
                    style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                if (guildId != null)
                  GestureDetector(
                    onTap: () {
                      final controller =
                      Provider.of<MainContentController>(context, listen: false);
                      controller.setCustomContent(GuildProfileScreen(guildId: guildId));
                    },
                    child: Text(
                      "🏰 Guild: [$guildTag]",
                      style: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                if (createdAt != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    "Joined on ${createdAt.toLocal().toString().split(' ')[0]}",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
                const SizedBox(height: 32),
                const Divider(),
                const Text("More profile features coming soon™ 🧙‍♂️"),
              ],
            ),
          );
        },
      ),
    );
  }
}
