import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roots_app/modules/combat/views/combat_log_screen.dart';
import 'package:roots_app/screens/helpers/layout_helper.dart';

class ReportDetailScreen extends StatelessWidget {
  final String heroId;
  final String reportId;

  const ReportDetailScreen({
    super.key,
    required this.heroId,
    required this.reportId,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize =
        LayoutHelper.getSizeCategory(MediaQuery.of(context).size.width);
    final isMobile = screenSize == ScreenSizeCategory.small;

    final reportRef = FirebaseFirestore.instance
        .collection('heroes')
        .doc(heroId)
        .collection('eventReports')
        .doc(reportId);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            if (isMobile && Navigator.canPop(context))
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
            const SizedBox(width: 8),
            const Text("Report Details"),
          ],
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: reportRef.get(),
        builder: (context, snapshot) {
          // Check the connection state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // Check for errors
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          // Check if the document exists and is non-null
          if (!snapshot.hasData ||
              snapshot.data == null ||
              !snapshot.data!.exists) {
            return const Center(child: Text("No report found."));
          }

          // Now try to retrieve the document data as a Map
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data == null) {
            return const Center(child: Text("Report data is empty."));
          }

          final type = data['type'] ?? 'unknown';
          final title = data['title'] ?? 'Event';
          final message = data['message'] ?? 'No message provided.';
          final xp = data['xp'];
          final combatIdValue = data['combatId'];

          // For combat reports, display the CombatLogScreen with detailed logs.
          if (type == 'combat') {
            if (combatIdValue != null) {
              return CombatLogScreen(combatId: combatIdValue);
            } else {
              return const Center(
                  child: Text("⚠️ No combat ID found in report."));
            }
          }

          // For non-combat reports, display the event details.
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                Text(message),
                if (xp != null) ...[
                  const SizedBox(height: 12),
                  Text("⭐ Gained XP: $xp"),
                ]
              ],
            ),
          );
        },
      ),
    );
  }
}
