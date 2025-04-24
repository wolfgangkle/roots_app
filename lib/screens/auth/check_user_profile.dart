import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roots_app/profile/models/user_profile_model.dart';
import 'package:roots_app/screens/auth/login_screen.dart';
import 'package:roots_app/screens/home/main_home_screen.dart';
import 'package:roots_app/modules/onboard/views/onboarding_entry.dart';
import 'package:roots_app/screens/controllers/main_content_controller.dart';
import 'package:roots_app/modules/settings/models/user_settings_model.dart';
import 'package:roots_app/modules/map/providers/terrain_provider.dart';

class CheckUserProfile extends StatefulWidget {
  const CheckUserProfile({super.key});

  @override
  _CheckUserProfileState createState() => _CheckUserProfileState();
}

class _CheckUserProfileState extends State<CheckUserProfile> {
  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      });
    } else {
      final profileRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('profile');

      profileRef.doc('main').get().then((doc) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (doc.exists) {
            final data = doc.data();

            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => MultiProvider(
                  providers: [
                    ChangeNotifierProvider(
                      create: (_) => UserProfileModel.fromJson(data ?? {}),
                    ),
                    ChangeNotifierProvider(
                      create: (_) => UserSettingsModel(),
                    ),
                  ],
                  child: const MainHomeScreen(),
                ),
              ),
            );
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const OnboardingEntry()),
            );
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
