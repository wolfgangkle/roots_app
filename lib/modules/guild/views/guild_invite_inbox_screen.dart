import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class GuildInviteInboxScreen extends StatefulWidget {
  const GuildInviteInboxScreen({super.key});

  @override
  State<GuildInviteInboxScreen> createState() => _GuildInviteInboxScreenState();
}

class _GuildInviteInboxScreenState extends State<GuildInviteInboxScreen> {
  String? _inviteProcessing;

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
                  final isProcessing = _inviteProcessing == inviteId;

                  return Card(
                    child: ListTile(
                      title: Text("[$guildTag] $guildName"),
                      subtitle: Text("Invited by: $fromUserId"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: isProcessing
                                ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                                : const Icon(Icons.check, color: Colors.green),
                            tooltip: "Accept",
                            onPressed: isProcessing
                                ? null
                                : () async {
                              setState(() => _inviteProcessing = inviteId);
                              try {
                                await FirebaseFunctions.instance
                                    .httpsCallable('acceptGuildInvite')
                                    .call({'guildId': guildId});
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Joined guild!")),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Error: $e")),
                                  );
                                }
                              } finally {
                                if (mounted) setState(() => _inviteProcessing = null);
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            tooltip: "Decline",
                            onPressed: isProcessing
                                ? null
                                : () async {
                              setState(() => _inviteProcessing = inviteId);
                              try {
                                await FirebaseFirestore.instance
                                    .doc('guildInvites/$inviteId')
                                    .update({'status': 'declined'});
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Invitation declined.")),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Error: $e")),
                                  );
                                }
                              } finally {
                                if (mounted) setState(() => _inviteProcessing = null);
                              }
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
