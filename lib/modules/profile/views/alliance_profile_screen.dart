import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:roots_app/modules/profile/views/guild_profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:roots_app/screens/controllers/main_content_controller.dart';

class AllianceProfileScreen extends StatelessWidget {
  final String allianceId;

  const AllianceProfileScreen({super.key, required this.allianceId});

  @override
  Widget build(BuildContext context) {
    final allianceRef = FirebaseFirestore.instance.collection('alliances').doc(allianceId);

    return FutureBuilder<DocumentSnapshot>(
      future: allianceRef.get(),
      builder: (context, allianceSnapshot) {
        if (allianceSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!allianceSnapshot.hasData || !allianceSnapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text("Alliance not found.")),
          );
        }

        final allianceData = allianceSnapshot.data!.data() as Map<String, dynamic>? ?? {};
        final name = allianceData['name'] ?? 'Unknown Alliance';
        final tag = allianceData['tag'] ?? '';
        final description = allianceData['description'] ?? '';
        final createdAt = (allianceData['createdAt'] as Timestamp?)?.toDate();

        return Scaffold(
          appBar: AppBar(
            title: Text("[$tag] $name"),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (description.isNotEmpty)
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  )
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
                const Divider(),
                const Text(
                  "Guilds in this Alliance:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('guilds')
                      .where('allianceId', isEqualTo: allianceId)
                      .get(),
                  builder: (context, guildSnapshot) {
                    if (guildSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!guildSnapshot.hasData || guildSnapshot.data!.docs.isEmpty) {
                      return const Text(
                        "No guilds currently part of this alliance.",
                        style: TextStyle(color: Colors.grey),
                      );
                    }

                    final controller = Provider.of<MainContentController>(context, listen: false);

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: guildSnapshot.data!.docs.length,
                      separatorBuilder: (_, __) => const Divider(height: 0),
                      itemBuilder: (context, index) {
                        final guild = guildSnapshot.data!.docs[index].data() as Map<String, dynamic>;
                        final guildId = guildSnapshot.data!.docs[index].id;
                        final tag = guild['tag'] ?? '';
                        final name = guild['name'] ?? 'Unknown';

                        return ListTile(
                          title: Text(
                            "[$tag] $name",
                            style: const TextStyle(
                              color: Colors.blueAccent,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          onTap: () {
                            controller.setCustomContent(GuildProfileScreen(guildId: guildId));
                          },
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
