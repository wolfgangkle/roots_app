import 'package:flutter/material.dart';
import 'package:roots_app/screens/home/panels/navigation_list_content.dart';

class NavigationDrawerPanel extends StatelessWidget {
  const NavigationDrawerPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return const Drawer(
      child: NavigationListContent(),
    );
  }
}
