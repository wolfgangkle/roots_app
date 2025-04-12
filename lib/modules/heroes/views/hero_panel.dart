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

  Stream<List<HeroModel>> _heroStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('heroes')
        .where('ownerId', isEqualTo: user.uid)
        .snapshots()
        .map((query) => query.docs.map((doc) {
      return HeroModel.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
    }).toList());
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<HeroModel>>(
      stream: _heroStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final heroes = snapshot.data;

        if (heroes == null || heroes.isEmpty) {
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

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: heroes.length,
          itemBuilder: (context, index) {
            final hero = heroes[index];
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
      },
    );
  }
}
