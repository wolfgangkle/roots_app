import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roots_app/profile/models/user_profile_model.dart';

class GuildRoleManagerScreen extends StatelessWidget {
  const GuildRoleManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<UserProfileModel>();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final guildId = profile.guildId;
    final userRole = profile.guildRole;

    if (guildId == null || (userRole != 'leader' && userRole != 'officer')) {
      return const Center(child: Text("You don't have permission to manage roles."));
    }

    final query = FirebaseFirestore.instance
        .collectionGroup('profile')
        .where('guildId', isEqualTo: guildId);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Guild Roles')),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading members: ${snapshot.error}'));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final userId = docs[index].reference.parent.parent?.id;
              final heroName = data['heroName'] ?? 'Unknown';
              final memberRole = data['guildRole'] ?? 'member';
              final isSelf = userId == currentUserId;

              return ListTile(
                leading: Icon(
                  memberRole == 'leader'
                      ? Icons.verified
                      : memberRole == 'officer'
                      ? Icons.star
                      : Icons.person,
                ),
                title: Text(heroName + (isSelf ? " (You)" : "")),
                subtitle: Text(memberRole),
                trailing: isSelf || userRole == 'officer' && memberRole == 'leader'
                    ? null
                    : _RoleActionsMenu(
                  userId: userId!,
                  currentRole: memberRole,
                  isLeader: userRole == 'leader',
                ),
              );
            },
          );
        },
      ),
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
            content: Text("This will change the member's role."),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Confirm")),
            ],
          ),
        );

        if (confirm != true) return;

        // TODO: Replace with a Cloud Function or proper security-checked update.
        String? newRole;
        if (value == 'promote') {
          newRole = 'officer';
        } else if (value == 'demote') {
          newRole = 'member';
        } else if (value == 'kick') {
          newRole = null;
        }

        final ref = FirebaseFirestore.instance.doc('users/$userId/profile/main');

        await ref.update({
          'guildRole': newRole,
          if (newRole == null) 'guildId': FieldValue.delete(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(newRole == null ? "Member kicked." : "Role updated.")),
        );
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
