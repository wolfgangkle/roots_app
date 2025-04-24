import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roots_app/profile/models/user_profile_model.dart';

class GuildMembersScreen extends StatelessWidget {
  const GuildMembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<UserProfileModel>();
    final guildId = profile.guildId;

    if (guildId == null) {
      return const Center(child: Text("You are not in a guild."));
    }

    final query = FirebaseFirestore.instance
        .collectionGroup('profile')
        .where('guildId', isEqualTo: guildId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guild Members'),
      ),
      body: StreamBuilder<QuerySnapshot>(
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
            return const Center(
              child: Text("No guild members found."),
            );
          }

          final docs = snapshot.data!.docs;
          final currentUserId = FirebaseAuth.instance.currentUser?.uid;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
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
              );
            },
          );
        },
      ),
    );
  }
}
