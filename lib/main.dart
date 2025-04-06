import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/firebase_options.dart';
import 'package:roots_app/screens/auth/check_user_profile.dart';
import 'package:roots_app/screens/dev/map_editor_screen.dart';
import 'package:roots_app/screens/home/main_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('✅ Firebase initialized successfully');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Roots',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.light,
      routes: {
        '/map_editor': (_) => const MapEditorScreen(),
        '/village': (_) => const MainHomeScreen(),
      },
      // Instead of starting with the LoginScreen, we start with CheckUserProfile,
      // which will determine whether the user is logged in and has a profile.
      home: const CheckUserProfile(),
    );
  }
}
