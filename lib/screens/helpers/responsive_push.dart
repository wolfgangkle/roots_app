import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roots_app/screens/controllers/main_content_controller.dart';

bool isMobile(BuildContext context) => MediaQuery.of(context).size.width < 800;

void pushResponsiveScreen(BuildContext context, Widget screen) {
  if (isMobile(context)) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  } else {
    final controller = Provider.of<MainContentController>(context, listen: false);
    controller.setCustomContent(screen);
  }
}
