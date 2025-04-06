import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:roots_app/screens/auth/login_screen.dart';
import 'package:roots_app/screens/home/main_home_screen.dart';
import 'package:roots_app/modules/onboard/views/onboarding_entry.dart';

class CheckUserProfile extends StatefulWidget {
  const CheckUserProfile({super.key});

  @override
  _CheckUserProfileState createState() => _CheckUserProfileState();
}

class _CheckUserProfileState extends State<CheckUserProfile> {
  @override
  void initState() {
    super.initState();
    // Check immediately: if there's no user, redirect to the LoginScreen.
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Delay the navigation to allow the widget tree to build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // While waiting for redirection (or if user is null), show a loading indicator.
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final profileRef =
    FirebaseFirestore.instance.collection('users').doc(user.uid).collection('profile');

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
