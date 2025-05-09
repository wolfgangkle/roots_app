import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

class InviteGuildMemberScreen extends StatefulWidget {
  const InviteGuildMemberScreen({super.key});

  @override
  State<InviteGuildMemberScreen> createState() =>
      _InviteGuildMemberScreenState();
}

class _InviteGuildMemberScreenState extends State<InviteGuildMemberScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;
  bool _inviteInProgress = false;
  List<DocumentSnapshot> _results = [];

  Future<void> _search() async {
    setState(() {
      _isLoading = true;
      _results = [];
    });

    final query = await FirebaseFirestore.instance
        .collectionGroup('profile')
        .where('heroName', isGreaterThanOrEqualTo: _searchQuery)
        .where('heroName', isLessThanOrEqualTo: '$_searchQuery\uf8ff')
        .limit(20)
        .get();

    setState(() {
      _results = query.docs;
      _isLoading = false;
    });
  }

  Future<void> _sendInvite(String toUserId, String heroName) async {
    setState(() => _inviteInProgress = true);

    final messenger = ScaffoldMessenger.of(context); // ✅ Capture before await

    try {
      final callable =
      FirebaseFunctions.instance.httpsCallable('sendGuildInvite');
      await callable.call({'toUserId': toUserId});

      messenger.showSnackBar(
        SnackBar(content: Text('Invitation sent to $heroName!')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to send invite: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _inviteInProgress = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invite Player to Guild')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by Hero Name',
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
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final doc = _results[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final userId = doc.reference.parent.parent?.id;
                  final heroName = data['heroName'] ?? 'Unknown';
                  final alreadyInGuild = data['guildId'] != null;

                  return ListTile(
                    title: Text(heroName),
                    subtitle: Text(alreadyInGuild
                        ? 'Already in a guild'
                        : 'Not in a guild'),
                    trailing: alreadyInGuild
                        ? null
                        : ElevatedButton(
                      onPressed: _inviteInProgress
                          ? null
                          : () => _sendInvite(userId!, heroName),
                      child: _inviteInProgress
                          ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2),
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
