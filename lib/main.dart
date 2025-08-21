import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'config/firebase_options.dart';
import 'package:roots_app/screens/auth/check_user_profile.dart';
import 'package:roots_app/screens/home/main_home_screen.dart';
import 'package:roots_app/screens/controllers/main_content_controller.dart';
import 'package:roots_app/modules/map/providers/terrain_provider.dart';
import 'package:roots_app/modules/settings/models/user_settings_model.dart';
import 'package:roots_app/widgets/global_background.dart';
import 'package:roots_app/theme/app_style_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (kDebugMode) {
    debugPrint('✅ Firebase initialized successfully');
  }

  final userSettingsModel = UserSettingsModel();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MainContentController()),
        ChangeNotifierProvider(create: (_) => TerrainProvider()),
        ChangeNotifierProvider.value(value: userSettingsModel),
        ChangeNotifierProvider(create: (_) => StyleManager()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<UserSettingsModel>();

    // ⏳ Wait for Firestore user settings to load
    if (!settings.isLoaded) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    // 🌿 Currently, we don’t use Flutter’s native light/dark themes anymore,
    // because our token-based styles handle all visual customization.
    return MaterialApp(
      title: 'Roots',
      debugShowCheckedModeBanner: false,

      // 🌄 Apply global background via builder
      builder: (context, child) {
        return GlobalBackground(child: child ?? const SizedBox());
      },

      routes: {
        '/village': (_) => const MainHomeScreen(),
      },
      home: const CheckUserProfile(),
    );
  }
}
