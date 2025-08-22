// lib/screens/home/panels/main_content_panel.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roots_app/screens/controllers/main_content_controller.dart';
import 'package:roots_app/screens/home/welcome_screen.dart';
import 'package:roots_app/theme/app_style_manager.dart';

class MainContentPanel extends StatelessWidget {
  const MainContentPanel({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuild when theme switches (children may depend on it)
    context.watch<StyleManager>();

    final controller = context.watch<MainContentController>();
    final content = controller.currentContent;

    return Material(
      type: MaterialType.transparency, // fully transparent surface
      child: Padding(
        padding: const EdgeInsets.all(16), // <-- named argument
        child: content ?? const WelcomeScreen(),
      ),
    );
  }
}
