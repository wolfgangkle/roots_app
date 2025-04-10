import 'package:flutter/material.dart'; // ✅ required for Text, Center, etc.
import 'package:roots_app/screens/controllers/main_content_controller.dart';

class MainContentPanel extends StatelessWidget {
  final MainContentController controller;

  const MainContentPanel({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    debugPrint('[MainContentPanel] build() called');
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final content = controller.currentContent;
        debugPrint('[MainContentPanel] currentContent is: ${content != null ? content.runtimeType : 'null'}');

        return Container(
          color: Colors.grey.shade100,
          padding: const EdgeInsets.all(16),
          child: content ??
              const Center(
                child: Text(
                  '🗺️ Main Game View\nSelect a village to begin!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
              ),
        );
      },
    );
  }
}
