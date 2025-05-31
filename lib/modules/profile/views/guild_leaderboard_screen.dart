import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class GuildLeaderboardScreen extends StatelessWidget {
  const GuildLeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🏰 Guild Leaderboard')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('guilds')
            .orderBy('points', descending: true)
            .limit(100)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No guilds have proven their glory yet.'));
          }

          final docs = snapshot.data!.docs;

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final name = data['name'] ?? 'Unnamed Guild';
              final points = data['points'] ?? 0;
              final rank = index + 1;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.brown.shade700,
                  child: Text(
                    '$rank',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(name),
                trailing: Text(
                  '$points pts',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15, // 🎯 Clean and consistent
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
