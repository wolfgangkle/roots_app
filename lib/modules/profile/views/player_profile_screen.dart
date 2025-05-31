import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roots_app/modules/profile/views/guild_profile_screen.dart';
import 'package:roots_app/modules/profile/views/alliance_profile_screen.dart';
import 'package:roots_app/screens/controllers/main_content_controller.dart';

class PlayerProfileScreen extends StatelessWidget {
  final String userId;

  const PlayerProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final profileRef = FirebaseFirestore.instance.doc('users/$userId/profile/main');
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return FutureBuilder<DocumentSnapshot>(
      future: profileRef.get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;

        if (data == null) {
          return const Scaffold(
            body: Center(child: Text("Player profile not found.")),
          );
        }

        final heroName = data['heroName'] ?? 'Unnamed Hero';
        final buildingPoints = data['totalBuildingPoints'] ?? 0;
        final heroPoints = data['totalHeroPoints'] ?? 0;
        final totalPoints = buildingPoints + heroPoints;
        final guildId = data['guildId'];
        final guildTag = data['guildTag'];
        final allianceId = data['allianceId'];
        final allianceTag = data['allianceTag'];
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

        final controller = Provider.of<MainContentController>(context, listen: false);

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                if (allianceTag != null && allianceId != null)
                  GestureDetector(
                    onTap: () {
                      controller.setCustomContent(AllianceProfileScreen(allianceId: allianceId));
                    },
                    child: Text(
                      '[$allianceTag] ',
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
                      '[$guildTag] ',
                      style: const TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                Flexible(
                  child: Text(
                    heroName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (userId == currentUserId) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      "You",
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("🎯 $totalPoints pts",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text("🏗️ $buildingPoints   ⚔️ $heroPoints",
                    style: const TextStyle(color: Colors.grey)),
                if (createdAt != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    "Joined on ${createdAt.toLocal().toString().split(' ')[0]}",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
