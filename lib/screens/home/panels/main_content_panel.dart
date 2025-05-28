import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roots_app/screens/controllers/main_content_controller.dart';
import 'package:roots_app/screens/home/welcome_screen.dart'; // 👈 add this

class MainContentPanel extends StatelessWidget {
  const MainContentPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<MainContentController>(context);
    final content = controller.currentContent;

    debugPrint('[MainContentPanel] build() called');
    debugPrint(
        '[MainContentPanel] currentContent is: ${content != null ? content.runtimeType : 'null'}');

    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.all(16),
      child: content ?? const WelcomeScreen(), // 👈 use your new screen here!
    );
  }
}
