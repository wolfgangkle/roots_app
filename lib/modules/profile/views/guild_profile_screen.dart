import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:roots_app/modules/profile/views/player_profile_screen.dart';
import 'package:roots_app/screens/controllers/main_content_controller.dart';

class GuildProfileScreen extends StatefulWidget {
  final String guildId;

  const GuildProfileScreen({super.key, required this.guildId});

  @override
  State<GuildProfileScreen> createState() => _GuildProfileScreenState();
}

class _GuildProfileScreenState extends State<GuildProfileScreen> {
  bool _showMembers = false;

  @override
  Widget build(BuildContext context) {
    final guildRef = FirebaseFirestore.instance.collection('guilds').doc(widget.guildId);

    return FutureBuilder<DocumentSnapshot>(
      future: guildRef.get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text("Guild not found.")),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final name = data['name'] ?? 'Unknown';
        final tag = data['tag'] ?? '';
        final description = data['description'] ?? '';
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

        return Scaffold(
          appBar: AppBar(
            title: Text(
              "[$tag] $name",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (description.isNotEmpty)
                  Text(description, style: Theme.of(context).textTheme.bodyLarge)
                else
                  Text("(No description set.)", style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 12),
                if (createdAt != null)
                  Text(
                    "Founded on ${DateFormat('yyyy-MM-dd').format(createdAt)}",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                const SizedBox(height: 24),

                /// Expandable Members Section
                ExpansionTile(
                  title: const Text("👥 Members"),
                  initiallyExpanded: _showMembers,
                  onExpansionChanged: (expanded) {
                    setState(() {
                      _showMembers = expanded;
                    });
                  },
                  children: [
                    FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance
                          .collectionGroup('profile')
                          .where('guildId', isEqualTo: widget.guildId)
                          .orderBy('heroName')
                          .get(),
                      builder: (context, membersSnapshot) {
                        if (membersSnapshot.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final docs = membersSnapshot.data?.docs ?? [];

                        if (docs.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text("No members found."),
                          );
                        }

                        final controller = Provider.of<MainContentController>(context, listen: false);

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: docs.length,
                          separatorBuilder: (_, __) => const Divider(height: 0),
                          itemBuilder: (context, index) {
                            final profile = docs[index].data() as Map<String, dynamic>;
                            final userId = docs[index].reference.parent.parent?.id;
                            final name = profile['heroName'] ?? 'Unnamed Hero';
                            final tag = profile['guildTag'] ?? '';

                            return ListTile(
                              title: Text("[$tag] $name"),
                              onTap: () {
                                if (userId != null) {
                                  controller.setCustomContent(PlayerProfileScreen(userId: userId));
                                }
                              },
                            );
                          },
                        );
                      },
                    )
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
