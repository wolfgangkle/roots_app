import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AllianceProfileScreen extends StatelessWidget {
  final String allianceId;

  const AllianceProfileScreen({super.key, required this.allianceId});

  @override
  Widget build(BuildContext context) {
    final allianceRef =
    FirebaseFirestore.instance.collection('alliances').doc(allianceId);

    return Scaffold(
      appBar: AppBar(title: const Text('🌐 Alliance Profile')),
      body: FutureBuilder<DocumentSnapshot>(
        future: allianceRef.get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Alliance not found."));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final name = data['name'] ?? 'Unknown Alliance';
          final description = data['description'] ?? '';
          final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "🌐 $name",
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                if (description.isNotEmpty)
                  Text(description, style: Theme.of(context).textTheme.bodyLarge)
                else
                  Text(
                    "(No description set.)",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                const SizedBox(height: 12),
                if (createdAt != null)
                  Text(
                    "Founded on ${DateFormat('yyyy-MM-dd').format(createdAt)}",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                const SizedBox(height: 24),
                const Divider(),
                const Text(
                  "More alliance features coming soon™ 🤝",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
