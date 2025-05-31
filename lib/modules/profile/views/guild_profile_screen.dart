import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:roots_app/modules/profile/models/user_profile_model.dart';
import 'package:roots_app/modules/guild/views/guild_members_screen.dart';

class GuildProfileScreen extends StatelessWidget {
  final String guildId;

  const GuildProfileScreen({super.key, required this.guildId});

  @override
  Widget build(BuildContext context) {
    final guildRef = FirebaseFirestore.instance.collection('guilds').doc(guildId);

    return Scaffold(
      appBar: AppBar(title: const Text("🏰 Guild Profile")),
      body: FutureBuilder<DocumentSnapshot>(
        future: guildRef.get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Guild not found."));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final name = data['name'] ?? 'Unknown';
          final tag = data['tag'] ?? '';
          final description = data['description'] ?? '';
          final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "🏰 [$tag] $name",
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                if (description.isNotEmpty)
                  Text(description, style: Theme.of(context).textTheme.bodyLarge)
                else
                  Text(
                    "(No description set.)",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                const SizedBox(height: 12),
                if (createdAt != null)
                  Text(
                    "Founded on ${DateFormat('yyyy-MM-dd').format(createdAt)}",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.group),
                  label: const Text("View Members"),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const GuildMembersScreen()),
                    );
                  },
                ),
                const SizedBox(height: 24),
                const Divider(),
                const Text(
                  "More guild features coming soon™ 😎",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
