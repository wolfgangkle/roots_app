import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roots_app/profile/models/user_profile_model.dart';
import 'package:roots_app/modules/guild/views/invite_guild_member_screen.dart';
import 'package:roots_app/screens/controllers/main_content_controller.dart';

class GuildMembersScreen extends StatelessWidget {
  const GuildMembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<UserProfileModel>();
    final guildId = profile.guildId;
    final userRole = profile.guildRole;

    if (guildId == null) {
      return const Center(child: Text("You are not in a guild."));
    }

    final query = FirebaseFirestore.instance
        .collectionGroup('profile')
        .where('guildId', isEqualTo: guildId);

    return Scaffold(
      appBar: AppBar(title: const Text('Guild Members')),
      body: Column(
        children: [
          if (userRole == 'leader' || userRole == 'officer')
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.person_add),
                label: const Text("Invite Member"),
                onPressed: () {
                  final controller = Provider.of<MainContentController>(context, listen: false);
                  controller.setCustomContent(const InviteGuildMemberScreen());
                },
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  debugPrint("Guild member loading error: ${snapshot.error}");
                  return Center(child: Text("Error loading guild members:\n${snapshot.error}"));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No guild members found."));
                }

                final docs = snapshot.data!.docs;
                final currentUserId = FirebaseAuth.instance.currentUser?.uid;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final heroName = data['heroName'] ?? 'Unknown';
                    final role = data['guildRole'] ?? 'member';
                    final userId = docs[index].reference.parent.parent?.id;
                    final isCurrentUser = userId == currentUserId;

                    return ListTile(
                      leading: Icon(
                        role == 'leader'
                            ? Icons.verified
                            : role == 'officer'
                            ? Icons.star
                            : Icons.person,
                      ),
                      title: Text(
                        heroName + (isCurrentUser ? ' (You)' : ''),
                        style: isCurrentUser
                            ? const TextStyle(fontWeight: FontWeight.bold)
                            : null,
                      ),
                      subtitle: Text(role),
                      trailing: isCurrentUser && role != 'leader'
                          ? PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'leave') {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Leave Guild?'),
                                content: const Text(
                                    'Are you sure you want to leave the guild? This cannot be undone.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text("Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text("Leave"),
                                  ),
                                ],
                              ),
                            );

                            if (confirm != true) return;

                            try {
                              await FirebaseFunctions.instance
                                  .httpsCallable('leaveGuild')
                                  .call();

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('You left the guild.')),
                                );
                              }

                              // Optional: Redirect to Guild Dashboard or root screen
                              // final controller = Provider.of<MainContentController>(context, listen: false);
                              // controller.setCustomContent(const GuildScreen());
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Error: $e")),
                                );
                              }
                            }
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'leave',
                            child: Text('Leave Guild'),
                          ),
                        ],
                      )
                          : null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
