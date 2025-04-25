import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class GuildInviteInboxScreen extends StatelessWidget {
  const GuildInviteInboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      return const Center(child: Text("Not logged in."));
    }

    final invitesQuery = FirebaseFirestore.instance
        .collection('guildInvites')
        .where('toUserId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending');

    return Scaffold(
      appBar: AppBar(title: const Text("Guild Invitations")),
      body: StreamBuilder<QuerySnapshot>(
        stream: invitesQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No guild invites found."));
          }

          final invites = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: invites.length,
            itemBuilder: (context, index) {
              final doc = invites[index];
              final data = doc.data() as Map<String, dynamic>;
              final guildId = data['guildId'];
              final fromUserId = data['fromUserId'];
              final inviteId = doc.id;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.doc('guilds/$guildId').get(),
                builder: (context, guildSnap) {
                  final guildName = guildSnap.data?.get('name') ?? 'Unknown Guild';
                  final guildTag = guildSnap.data?.get('tag') ?? '???';

                  return Card(
                    child: ListTile(
                      title: Text("[$guildTag] $guildName"),
                      subtitle: Text("Invited by: $fromUserId"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            tooltip: "Accept",
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .doc('users/$currentUserId/profile/main')
                                  .update({
                                'guildId': guildId,
                                'guildRole': 'member',
                              });

                              await FirebaseFirestore.instance
                                  .doc('guildInvites/$inviteId')
                                  .update({'status': 'accepted'});

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Joined guild!")),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            tooltip: "Decline",
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .doc('guildInvites/$inviteId')
                                  .update({'status': 'declined'});

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Invitation declined.")),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
