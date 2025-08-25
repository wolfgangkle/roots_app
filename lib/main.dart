// lib/main.dart
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

// 🧭 Analytics
import 'package:firebase_analytics/firebase_analytics.dart';

// 🔤 Localization imports (matches l10n.yaml output)
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:roots_app/l10n/gen/app_localizations.dart';

// 🧭 Analytics singletons
late final FirebaseAnalytics analytics;
late final FirebaseAnalyticsObserver analyticsObserver;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (kDebugMode) {
    debugPrint('✅ Firebase initialized successfully');
  }

  // 🧭 Analytics init
  analytics = FirebaseAnalytics.instance;
  analyticsObserver = FirebaseAnalyticsObserver(analytics: analytics);

  // If you gate via consent, toggle this accordingly at runtime.
  await analytics.setAnalyticsCollectionEnabled(true);

  // Optional: quick “app opened” ping to see DebugView events immediately.
  await analytics.logAppOpen();

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

class LocaleGate extends StatelessWidget {
  final Locale? locale;
  final Widget child;
  const LocaleGate({super.key, required this.locale, required this.child});

  @override
  Widget build(BuildContext context) {
    // Changing the key forces a rebuild of the subtree when locale flips
    final key = ValueKey('gate-${locale?.toLanguageTag() ?? 'system'}');
    return KeyedSubtree(key: key, child: child);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<UserSettingsModel>();

    if (!settings.isLoaded) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp(
      // Recreate MaterialApp when locale changes (extra safety)
      key: ValueKey('locale-${settings.locale?.toLanguageTag() ?? 'system'}'),

      title: 'Roots',
      debugShowCheckedModeBanner: false,

      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: settings.locale, // null -> follow system

      builder: (context, child) {
        // ✅ Force immediate rebuild of the visible subtree when locale changes
        final wrapped = GlobalBackground(child: child ?? const SizedBox());
        return LocaleGate(locale: settings.locale, child: wrapped);
      },

      // 🧭 Hook Analytics screen tracking
      navigatorObservers: [analyticsObserver],

      routes: {
        '/village': (_) => const MainHomeScreen(),
      },
      home: const CheckUserProfile(),
    );
  }
}
