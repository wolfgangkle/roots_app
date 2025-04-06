import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/firebase_options.dart';
import 'package:roots_app/screens/auth/login_screen.dart';         // 👈 your login screen
import 'package:roots_app/screens/auth/check_user_profile.dart';       // 👈 handles onboarding redirect
import 'package:roots_app/screens/dev/map_editor_screen.dart'; //


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

      // ✅ Define both themes (optional if you're forcing one)
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),

      // ✅ Force light mode here
      themeMode: ThemeMode.light,  // <--- 👈 Forces light mode, override system setting

      // ⬇️ dev mode entry
      routes: {
        '/map_editor': (_) => const MapEditorScreen(),
      },

      home: const LoginScreen(),
    );
  }
}
