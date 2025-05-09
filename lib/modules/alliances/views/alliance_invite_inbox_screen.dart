import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roots_app/profile/models/user_profile_model.dart';

class AllianceInviteInboxScreen extends StatefulWidget {
  const AllianceInviteInboxScreen({super.key});

  @override
  State<AllianceInviteInboxScreen> createState() =>
      _AllianceInviteInboxScreenState();
}

class _AllianceInviteInboxScreenState
    extends State<AllianceInviteInboxScreen> {
  String? _inviteProcessing;

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<UserProfileModel>();
    final guildId = profile.guildId;
    final isLeader = profile.guildRole == 'leader';

    if (!isLeader || guildId == null) {
      return const Center(
          child: Text("Only guild leaders can view alliance invites."));
    }

    final invitesQuery = FirebaseFirestore.instance
        .collection('guilds')
        .doc(guildId)
        .collection('allianceInvites');

    return Scaffold(
      appBar: AppBar(title: const Text("Alliance Invitations")),
      body: StreamBuilder<QuerySnapshot>(
        stream: invitesQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No alliance invites found."));
          }

          final invites = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: invites.length,
            itemBuilder: (context, index) {
              final doc = invites[index];
              final data = doc.data() as Map<String, dynamic>;
              final allianceId = data['allianceId'];
              final invitedByGuildId = data['invitedByGuildId'];
              final inviteId = doc.id;
              final isProcessing = _inviteProcessing == inviteId;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .doc('alliances/$allianceId')
                    .get(),
                builder: (context, allianceSnap) {
                  final allianceData =
                      allianceSnap.data?.data() as Map<String, dynamic>? ?? {};
                  final allianceName =
                      allianceData['name'] ?? 'Unknown Alliance';
                  final allianceTag = allianceData['tag'] ?? '???';

                  return Card(
                    child: ListTile(
                      title: Text("[$allianceTag] $allianceName"),
                      subtitle: FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .doc('guilds/$invitedByGuildId')
                            .get(),
                        builder: (context, guildSnap) {
                          final guildData =
                              guildSnap.data?.data() as Map<String, dynamic>? ??
                                  {};
                          final byTag = guildData['tag'] ?? '???';
                          final byName = guildData['name'] ?? 'Unknown Guild';
                          return Text("Invited by: [$byTag] $byName");
                        },
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: isProcessing
                                ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2),
                            )
                                : const Icon(Icons.check, color: Colors.green),
                            tooltip: "Accept",
                            onPressed: isProcessing
                                ? null
                                : () async {
                              final messenger =
                              ScaffoldMessenger.of(context);
                              setState(() =>
                              _inviteProcessing = inviteId);
                              try {
                                await FirebaseFunctions.instance
                                    .httpsCallable('acceptAllianceInvite')
                                    .call({'allianceId': allianceId});

                                messenger.showSnackBar(
                                  const SnackBar(
                                      content: Text("Joined alliance!")),
                                );
                              } catch (e) {
                                messenger.showSnackBar(
                                  SnackBar(content: Text("Error: $e")),
                                );
                              } finally {
                                if (mounted) {
                                  setState(
                                          () => _inviteProcessing = null);
                                }
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            tooltip: "Decline",
                            onPressed: isProcessing
                                ? null
                                : () async {
                              final messenger =
                              ScaffoldMessenger.of(context);
                              setState(() =>
                              _inviteProcessing = inviteId);
                              try {
                                await FirebaseFirestore.instance
                                    .doc(
                                    'guilds/$guildId/allianceInvites/$inviteId')
                                    .delete();

                                messenger.showSnackBar(
                                  const SnackBar(
                                      content:
                                      Text("Invitation declined.")),
                                );
                              } catch (e) {
                                messenger.showSnackBar(
                                  SnackBar(content: Text("Error: $e")),
                                );
                              } finally {
                                if (mounted) {
                                  setState(
                                          () => _inviteProcessing = null);
                                }
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
