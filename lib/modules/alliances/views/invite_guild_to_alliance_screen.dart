import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class InviteGuildToAllianceScreen extends StatefulWidget {
  const InviteGuildToAllianceScreen({super.key});

  @override
  State<InviteGuildToAllianceScreen> createState() => _InviteGuildToAllianceScreenState();
}

class _InviteGuildToAllianceScreenState extends State<InviteGuildToAllianceScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;
  bool _inviteInProgress = false;
  List<Map<String, dynamic>> _guildInfos = [];

  Future<void> _search() async {
    setState(() {
      _isLoading = true;
      _guildInfos = [];
    });

    final query = await FirebaseFirestore.instance
        .collection('guilds')
        .where('name', isGreaterThanOrEqualTo: _searchQuery)
        .where('name', isLessThanOrEqualTo: _searchQuery + '\uf8ff')
        .limit(20)
        .get();

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    DocumentSnapshot? userProfileDoc;
    String? allianceId;

    if (currentUserId != null) {
      userProfileDoc = await FirebaseFirestore.instance
          .doc('users/$currentUserId/profile/main')
          .get();

      final profileData = userProfileDoc.data() as Map<String, dynamic>?;
      final guildId = profileData?['guildId'];

      if (guildId != null) {
        final guildDoc = await FirebaseFirestore.instance.doc('guilds/$guildId').get();
        allianceId = guildDoc.data()?['allianceId'];
      }
    }

    final results = await Future.wait(query.docs.map((doc) async {
      final data = doc.data();
      final guildId = doc.id;

      String leaderName = 'Unknown';
      int memberCount = 0;
      bool hasPendingInvite = false;

      try {
        // Count members
        final membersQuery = await FirebaseFirestore.instance
            .collectionGroup('profile')
            .where('guildId', isEqualTo: guildId)
            .get();
        memberCount = membersQuery.size;

        // Find leader
        QueryDocumentSnapshot<Map<String, dynamic>>? leaderDoc;
        try {
          leaderDoc = membersQuery.docs.firstWhere(
                (doc) => doc.data()['guildRole'] == 'leader',
          );
        } catch (_) {
          leaderDoc = null;
        }

        if (leaderDoc != null) {
          leaderName = leaderDoc.data()['heroName'] ?? 'Unknown';
        }

        // Check for pending invite
        if (allianceId != null) {
          final inviteDoc = await FirebaseFirestore.instance
              .doc('guilds/$guildId/allianceInvites/$allianceId')
              .get();
          hasPendingInvite = inviteDoc.exists;
        }
      } catch (_) {}

      return {
        'id': guildId,
        'name': data['name'],
        'tag': data['tag'],
        'hasAlliance': data['allianceId'] != null,
        'leaderName': leaderName,
        'memberCount': memberCount,
        'hasPendingInvite': hasPendingInvite,
      };
    }));

    if (mounted) {
      setState(() {
        _guildInfos = results;
        _isLoading = false;
      });
    }
  }

  Future<void> _sendInvite(String guildId, String guildName) async {
    setState(() => _inviteInProgress = true);

    try {
      final callable = FirebaseFunctions.instance.httpsCallable('sendAllianceInvite');
      await callable.call({'targetGuildId': guildId});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Invite sent to "$guildName"!')),
        );

        // Refresh list to reflect updated status
        _search();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send invite: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _inviteInProgress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invite Guild to Alliance')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Guild by Name',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    setState(() {
                      _searchQuery = _searchController.text.trim();
                    });
                    _search();
                  },
                ),
              ),
              onSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 16),
            if (_isLoading) const LinearProgressIndicator(),
            Expanded(
              child: ListView.builder(
                itemCount: _guildInfos.length,
                itemBuilder: (context, index) {
                  final info = _guildInfos[index];

                  return ListTile(
                    title: Text('[${info['tag']}] ${info['name']}'),
                    subtitle: Text(
                      info['hasAlliance']
                          ? 'Already in an alliance'
                          : 'Leader: ${info['leaderName']} • Members: ${info['memberCount']}',
                    ),
                    trailing: info['hasAlliance']
                        ? null
                        : info['hasPendingInvite']
                        ? const Text('Pending', style: TextStyle(color: Colors.grey))
                        : ElevatedButton(
                      onPressed: _inviteInProgress
                          ? null
                          : () => _sendInvite(info['id'], info['name']),
                      child: _inviteInProgress
                          ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Text('Invite'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
