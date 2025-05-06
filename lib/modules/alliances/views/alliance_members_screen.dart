import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roots_app/profile/models/user_profile_model.dart';
import 'package:roots_app/screens/controllers/main_content_controller.dart';
import 'package:roots_app/modules/alliances/views/invite_guild_to_alliance_screen.dart';

class AllianceMembersScreen extends StatelessWidget {
  const AllianceMembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<UserProfileModel>();
    final allianceId = profile.allianceId;
    final isGuildLeader = profile.guildRole == 'leader';
    final isAllianceLeader = profile.allianceRole == 'leader';

    if (allianceId == null) {
      return const Center(child: Text("You are not in an alliance."));
    }

    final allianceRef = FirebaseFirestore.instance.collection('alliances').doc(allianceId);

    return FutureBuilder<DocumentSnapshot>(
      future: allianceRef.get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final alliance = snapshot.data!.data() as Map<String, dynamic>?;
        if (alliance == null) return const Center(child: Text("Alliance data not found."));

        final guildIds = List<String>.from(alliance['guildIds'] ?? []);

        return Scaffold(
          appBar: AppBar(title: Text('[${alliance['tag']}] ${alliance['name']}')),
          body: Column(
            children: [
              if (isAllianceLeader)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.group_add),
                    label: const Text("Invite Guild"),
                    onPressed: () {
                      final isMobile = MediaQuery.of(context).size.width < 600;

                      if (isMobile) {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const InviteGuildToAllianceScreen()),
                        );
                      } else {
                        final controller = Provider.of<MainContentController>(context, listen: false);
                        controller.setCustomContent(const InviteGuildToAllianceScreen());
                      }
                    },
                  ),
                ),
              if (alliance['description'] != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(alliance['description'], style: const TextStyle(fontSize: 16)),
                ),
              const SizedBox(height: 8),
              Expanded(
                child: FutureBuilder<List<DocumentSnapshot>>(
                  future: _fetchGuilds(guildIds),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const CircularProgressIndicator();
                    final docs = snapshot.data!;
                    final currentGuildId = profile.guildId;

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final guildId = docs[index].id;
                        final tag = data['tag'] ?? '???';
                        final name = data['name'] ?? 'Unknown';
                        final isCurrentGuild = guildId == currentGuildId;

                        return ListTile(
                          leading: const Icon(Icons.shield),
                          title: Text('[$tag] $name',
                              style: isCurrentGuild
                                  ? const TextStyle(fontWeight: FontWeight.bold)
                                  : null),
                          subtitle: isCurrentGuild ? const Text('Your Guild') : null,
                          trailing: isCurrentGuild && isGuildLeader
                              ? PopupMenuButton<String>(
                            onSelected: (value) => _handleLeaveOrDisband(context, value == 'disband'),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: isAllianceLeader ? 'disband' : 'leave',
                                child: Text(isAllianceLeader ? 'Disband Alliance' : 'Leave Alliance'),
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
      },
    );
  }

  Future<List<DocumentSnapshot>> _fetchGuilds(List<String> guildIds) async {
    if (guildIds.isEmpty) return [];
    final futures = guildIds.map((id) => FirebaseFirestore.instance.doc('guilds/$id').get());
    return await Future.wait(futures);
  }

  Future<void> _handleLeaveOrDisband(BuildContext context, bool disband) async {
    bool isProcessing = false;

    await showDialog<bool>(
      context: context,
      barrierDismissible: !isProcessing,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(disband ? 'Disband Alliance?' : 'Leave Alliance?'),
              content: Text(disband
                  ? 'This will permanently disband the alliance for all member guilds.'
                  : 'Are you sure your guild wants to leave the alliance?'),
              actions: [
                TextButton(
                  onPressed: isProcessing ? null : () => Navigator.pop(context, false),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: isProcessing
                      ? null
                      : () async {
                    setState(() => isProcessing = true);

                    final callable = FirebaseFunctions.instance.httpsCallable(
                      disband ? 'disbandAlliance' : 'leaveAlliance',
                    );

                    try {
                      await callable.call();

                      if (context.mounted) {
                        Navigator.pop(context, true); // close the dialog
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(disband ? "Alliance disbanded." : "Guild left alliance.")),
                        );

                        final controller = Provider.of<MainContentController>(context, listen: false);
                        controller.setCustomContent(const Placeholder()); // redirect
                      }
                    } catch (e) {
                      if (context.mounted) {
                        setState(() => isProcessing = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Error: $e")),
                        );
                      }
                    }
                  },
                  child: isProcessing
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(disband ? "Disband" : "Leave"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
