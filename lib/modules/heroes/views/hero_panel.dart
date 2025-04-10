import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:roots_app/modules/heroes/views/create_main_hero_screen.dart';
import 'package:roots_app/modules/heroes/views/hero_details_screen.dart';
import 'package:roots_app/modules/heroes/widgets/hero_card.dart';
import 'package:roots_app/modules/heroes/models/hero_model.dart';
import 'package:roots_app/screens/controllers/main_content_controller.dart';

class HeroPanel extends StatelessWidget {
  final MainContentController controller;

  const HeroPanel({required this.controller, Key? key}) : super(key: key);

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
                    controller.setCustomContent(const CreateMainHeroScreen());
                  },
                  child: const Text('Create Main Hero'),
                ),
              ],
            ),
          );
        }

        // Convert Firestore data to HeroModel
        final doc = snapshot.data!;
        final hero = HeroModel.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);

        final isMobile = MediaQuery.of(context).size.width < 1024;

        return HeroCard(
          hero: hero,
          onTap: () {
            if (isMobile) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => HeroDetailsScreen(hero: hero),
                ),
              );
            } else {
              controller.setCustomContent(HeroDetailsScreen(hero: hero));
            }
          },
        );
      },
    );
  }
}
