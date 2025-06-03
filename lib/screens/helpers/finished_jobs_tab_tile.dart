import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:roots_app/modules/reports/views/finished_jobs_screen.dart';
import 'package:roots_app/screens/controllers/main_content_controller.dart';


class FinishedJobsTabTile extends StatelessWidget {

  final bool isMobile;
  final bool isInDrawer;
  final void Function({required String title, required Widget content})? onSelectDynamicTab;

  const FinishedJobsTabTile({super.key, 
    required this.isMobile,
    required this.isInDrawer,
    required this.onSelectDynamicTab,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;
        if (user == null) {
          return _buildTab(context, 'Finished Jobs');
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collectionGroup('finishedJobs')
              .where('type', whereIn: ['upgrade', 'crafting'])
              .where('read', isEqualTo: false)
              .where('userId', isEqualTo: user.uid)
              .snapshots(),
          builder: (context, snapshot) {
            final unreadCount = snapshot.data?.docs.length ?? 0;
            final title = unreadCount > 0
                ? 'Finished Jobs ($unreadCount)'
                : 'Finished Jobs';
            return _buildTab(context, title);
          },
        );
      },
    );
  }

  Widget _buildTab(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        dense: true,
        visualDensity: VisualDensity.compact,
        leading: Icon(Icons.arrow_right, color: Theme.of(context).colorScheme.onSurface),
        title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
        onTap: () {
          if (isInDrawer) Navigator.pop(context);
          if (isMobile && onSelectDynamicTab != null) {
            onSelectDynamicTab!(title: title, content: const FinishedJobsScreen());
          } else {
            final controller = Provider.of<MainContentController>(context, listen: false);
            controller.setCustomContent(const FinishedJobsScreen());
          }
        },
      ),
    );
  }
}
