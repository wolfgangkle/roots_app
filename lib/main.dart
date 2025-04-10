import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'config/firebase_options.dart';
import 'package:roots_app/screens/auth/check_user_profile.dart';
import 'package:roots_app/screens/dev/map_editor_screen.dart';
import 'package:roots_app/screens/home/main_home_screen.dart';
import 'package:roots_app/screens/controllers/main_content_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('✅ Firebase initialized successfully');

  runApp(
    ChangeNotifierProvider(
      create: (_) => MainContentController(),
      child: const MyApp(),
    ),
  );
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
        '/village': (_) => const MainHomeScreen(), // ✅ Already has access to the controller now
      },
      // Start with login/profile check
      home: const CheckUserProfile(),
    );
  }
}
