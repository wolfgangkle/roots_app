import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HeroPanel extends StatelessWidget {
  const HeroPanel({Key? key}) : super(key: key);

  Future<DocumentSnapshot?> _getMainHero() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final query = await FirebaseFirestore.instance
        .collection('heroes')
        .where('ownerId', isEqualTo: user.uid)
        .where('type', isEqualTo: 'mage')
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) {
      return query.docs.first;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot?>(
      future: _getMainHero(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data == null) {
          // No hero exists yet: prompt the user to create one.
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'No hero found.\nCreate your main hero (mage)!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Navigate to the hero creation screen.
                    Navigator.pushNamed(context, '/createHero');
                  },
                  child: const Text('Create Hero'),
                ),
              ],
            ),
          );
        }

        // Hero exists: display the hero summary.
        final heroData = snapshot.data!.data() as Map<String, dynamic>;
        return Card(
          margin: const EdgeInsets.all(16),
          child: ListTile(
            title: Text(heroData['heroName'] ?? 'Unnamed Hero'),
            subtitle: Text('Level: ${heroData['level'] ?? 1}'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Optionally navigate to hero detail/update screen.
              Navigator.pushNamed(context, '/heroDetails');
            },
          ),
        );
      },
    );
  }
}
