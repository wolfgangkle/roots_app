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

    final isLeader = userRole == 'leader';
    final isOfficer = userRole == 'officer';

    return Scaffold(
      appBar: AppBar(title: const Text('Guild Members')),
      body: Column(
        children: [
          if (isLeader || isOfficer)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.person_add),
                label: const Text("Invite Member"),
                onPressed: () {
                  final isMobile = MediaQuery.of(context).size.width < 600;

                  if (isMobile) {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const InviteGuildMemberScreen()),
                    );
                  } else {
                    final controller = Provider.of<MainContentController>(context, listen: false);
                    controller.setCustomContent(const InviteGuildMemberScreen());
                  }
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
                  return Center(child: Text("Error loading guild members:\n${snapshot.error}"));
                }

                final docs = snapshot.data?.docs ?? [];
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
                        style: isCurrentUser ? const TextStyle(fontWeight: FontWeight.bold) : null,
                      ),
                      subtitle: Text(role),
                      trailing: isCurrentUser
                          ? role != 'leader'
                          ? _LeaveGuildMenu()
                          : null
                          : (isLeader || (isOfficer && role != 'leader'))
                          ? _RoleActionsMenu(
                        userId: userId!,
                        currentRole: role,
                        isLeader: isLeader,
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

class _LeaveGuildMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == 'leave') {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Leave Guild?'),
              content: const Text('Are you sure you want to leave the guild? This cannot be undone.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Leave")),
              ],
            ),
          );

          if (confirmed != true) return;

          try {
            await FirebaseFunctions.instance.httpsCallable('leaveGuild').call();

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('You left the guild.')),
              );
            }
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
    );
  }
}

class _RoleActionsMenu extends StatelessWidget {
  final String userId;
  final String currentRole;
  final bool isLeader;

  const _RoleActionsMenu({
    required this.userId,
    required this.currentRole,
    required this.isLeader,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Are you sure?"),
            content: const Text("This will change the member's role."),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Confirm")),
            ],
          ),
        );

        if (confirm != true) return;

        String? newRole;
        if (value == 'promote') {
          newRole = 'officer';
        } else if (value == 'demote') {
          newRole = 'member';
        } else if (value == 'kick') {
          newRole = null;
        }

        try {
          final callable = FirebaseFunctions.instance.httpsCallable('updateGuildRole');
          await callable.call({
            'targetUserId': userId,
            'newRole': newRole,
          });

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(newRole == null ? "Member kicked." : "Role updated.")),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e")),
          );
        }
      },
      itemBuilder: (context) {
        return [
          if (currentRole == 'member') const PopupMenuItem(value: 'promote', child: Text('Promote to Officer')),
          if (currentRole == 'officer') const PopupMenuItem(value: 'demote', child: Text('Demote to Member')),
          if (isLeader) const PopupMenuItem(value: 'kick', child: Text('Kick from Guild')),
        ];
      },
    );
  }
}
