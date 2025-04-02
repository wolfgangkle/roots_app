import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:roots_app/screens/auth/login_screen.dart';         // 👈 your login screen
import 'package:roots_app/screens/auth/check_user_profile.dart';       // 👈 handles onboarding redirect

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
      theme: ThemeData.dark(), // or whatever you use
      home: const LoginScreen(),   // 👈 start with login
    );
  }
}
