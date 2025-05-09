import 'package:flutter/material.dart';
import 'package:roots_app/screens/home/panels/navigation_list_content.dart';

class NavigationDrawerPanel extends StatelessWidget {
  final void Function({required String title, required Widget content})?
      onSelectDynamicTab;

  const NavigationDrawerPanel({super.key, this.onSelectDynamicTab});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: NavigationListContent(
        onSelectDynamicTab: onSelectDynamicTab,
        isInDrawer: true, // ✅ This is the fix
      ),
    );
  }
}
