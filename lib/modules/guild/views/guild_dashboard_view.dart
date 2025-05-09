import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class GuildDashboardView extends StatelessWidget {
  final String guildId;

  const GuildDashboardView({super.key, required this.guildId});

  @override
  Widget build(BuildContext context) {
    final docRef = FirebaseFirestore.instance.collection('guilds').doc(guildId);

    return FutureBuilder<DocumentSnapshot>(
      future: docRef.get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        if (data == null) {
          return const Center(child: Text("Guild not found."));
        }

        final name = data['name'] ?? 'Unknown';
        final tag = data['tag'] ?? '';
        final description = data['description'] ?? '';
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("🏰 [$tag] $name",
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 12),
              Text(description, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 12),
              if (createdAt != null)
                Text(
                    "Created on ${createdAt.toLocal().toString().split(' ')[0]}",
                    style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 24),
              const Divider(),
              const Text("Guild features coming soon™ 😎"),
            ],
          ),
        );
      },
    );
  }
}
