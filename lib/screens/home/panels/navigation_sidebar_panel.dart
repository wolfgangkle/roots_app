// lib/screens/home/panels/navigation_sidebar_panel.dart

import 'package:flutter/material.dart';
import 'package:roots_app/screens/home/panels/navigation_list_content.dart';

class NavigationSidebarPanel extends StatelessWidget {
  const NavigationSidebarPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      color: Colors.grey.shade200,
      child: const NavigationListContent(),
    );
  }
}
