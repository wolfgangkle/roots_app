import 'package:flutter/material.dart';
import 'package:roots_app/screens/home/panels/navigation_list_content.dart';

class NavigationSidebarPanel extends StatelessWidget {
  final void Function({required String title, required Widget content})? onSelectDynamicTab;

  const NavigationSidebarPanel({super.key, this.onSelectDynamicTab});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      color: Theme.of(context).colorScheme.surface,
      child: NavigationListContent(onSelectDynamicTab: onSelectDynamicTab),
    );
  }
}
