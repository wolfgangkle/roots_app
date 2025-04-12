import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:roots_app/screens/controllers/main_content_controller.dart';
import 'package:roots_app/modules/chat/chat_screen.dart';
import 'package:roots_app/screens/auth/login_screen.dart';
import 'package:roots_app/screens/dev/dev_mode.dart';
import 'package:roots_app/modules/reports/views/reports_list_screen.dart';
import 'package:roots_app/screens/helpers/layout_helper.dart';

class NavigationListContent extends StatelessWidget {
  final void Function({required String title, required Widget content})? onSelectDynamicTab;
  final bool isInDrawer;

  const NavigationListContent({
    super.key,
    this.onSelectDynamicTab,
    this.isInDrawer = false,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDevUser = user?.email == 'test@roots.dev';

    final screenWidth = MediaQuery.of(context).size.width;
    final screenSize = LayoutHelper.getSizeCategory(screenWidth);
    final isMobile = screenSize == ScreenSizeCategory.small;

    if (isDevUser) {
      DevMode.enabled = true;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('🏠 Home'),
        const SizedBox(height: 12),
        const Text('🗺️ Map'),
        const SizedBox(height: 12),
        const Text('🏡 Village'),
        const SizedBox(height: 12),
        const Text('🧙 Hero'),
        const SizedBox(height: 12),

        ListTile(
          leading: const Icon(Icons.notifications),
          title: const Text('📜 Reports'),
          onTap: () {
            debugPrint('[NavigationListContent] 📜 Reports tapped');

            if (isInDrawer) {
              debugPrint('[NavigationListContent] -> Closing drawer via Navigator.pop(context)');
              Navigator.pop(context);
            }

            if (isMobile && onSelectDynamicTab != null) {
              debugPrint('[NavigationListContent] -> Using DYNAMIC TAB for MOBILE');
              onSelectDynamicTab!(
                title: '📜 Reports',
                content: const ReportsListScreen(),
              );
            } else {
              debugPrint('[NavigationListContent] -> Using setCustomContent for DESKTOP');
              final controller = Provider.of<MainContentController>(context, listen: false);
              controller.setCustomContent(const ReportsListScreen());
            }
          },
        ),
        const SizedBox(height: 12),

        if (!isMobile)
          ListTile(
            leading: const Icon(Icons.chat),
            title: const Text('💬 Chat'),
            onTap: () {
              final controller = Provider.of<MainContentController>(context, listen: false);
              controller.setCustomContent(ChatScreen());
            },
          ),

        if (!isMobile) const SizedBox(height: 12),
        const Text('⚙️ Settings'),
        const SizedBox(height: 24),

        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Logout'),
          onTap: () async {
            await FirebaseAuth.instance.signOut();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          },
        ),
      ],
    );
  }
}
