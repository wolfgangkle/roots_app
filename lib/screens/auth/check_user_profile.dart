import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:roots_app/profile/models/user_profile_model.dart';
import 'package:roots_app/screens/auth/login_screen.dart';
import 'package:roots_app/screens/home/main_home_screen.dart';
import 'package:roots_app/modules/onboard/views/onboarding_entry.dart';
import 'package:roots_app/modules/settings/models/user_settings_model.dart';

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
          .collection('profile')
          .doc('main');

      profileRef.get().then((doc) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (doc.exists) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => MultiProvider(
                  providers: [
                    StreamProvider<UserProfileModel>(
                      create: (_) => _buildUserProfileStream(user.uid),
                      initialData: UserProfileModel(heroName: 'Loading...'),
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

  Stream<UserProfileModel> _buildUserProfileStream(String userId) {
    final profileRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('profile')
        .doc('main');

    return profileRef.snapshots().switchMap((profileSnap) {
      final profileData = profileSnap.data() ?? {};
      final guildId = profileData['guildId'];

      if (guildId == null) {
        return Stream.value(UserProfileModel(
          heroName: profileData['heroName'] ?? '🧙 Nameless',
          guildId: null,
          guildRole: null,
          allianceId: null,
          allianceRole: null,
        ));
      }

      final guildStream = FirebaseFirestore.instance.doc('guilds/$guildId').snapshots();

      return guildStream.map((guildSnap) {
        if (!guildSnap.exists) {
          // The guild was deleted (e.g. disbanded) – clean up stale profile data
          return UserProfileModel(
            heroName: profileData['heroName'] ?? '🧙 Nameless',
            guildId: null,
            guildRole: null,
            allianceId: null,
            allianceRole: null,
          );
        }

        final guildData = guildSnap.data()!;
        return UserProfileModel(
          heroName: profileData['heroName'] ?? '🧙 Nameless',
          guildId: guildId,
          guildRole: profileData['guildRole'],
          allianceId: guildData['allianceId'],
          allianceRole: guildData['allianceRole'],
        );
      });

    });
  }
}
