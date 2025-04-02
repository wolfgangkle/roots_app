
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../onboard/onboarding_entry.dart';
import '../home/main_home_screen.dart';

class CheckUserProfile extends StatelessWidget {
  const CheckUserProfile({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('User not logged in 😬'));
    }

    final profileRef = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('profile');

    return FutureBuilder<DocumentSnapshot>(
      future: profileRef.doc('main').get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data!.exists) {
          // User has already completed onboarding
          return const MainHomeScreen();
        } else {
          // New player, go to onboarding
          return const OnboardingEntry();
        }
      },
    );
  }
}
