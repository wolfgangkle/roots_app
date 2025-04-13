import 'package:flutter/material.dart';

bool isMobile(BuildContext context) => MediaQuery.of(context).size.width < 800;

/// Push a screen only if we're in mobile layout
void pushResponsiveScreen(BuildContext context, Widget screen) {
  if (isMobile(context)) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  } else {
    // Fallback: do nothing or log
    debugPrint('pushResponsiveScreen: Not a mobile layout');
  }
}
