import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roots_app/modules/combat/views/combat_log_screen.dart';
import 'package:roots_app/screens/helpers/layout_helper.dart';

class ReportDetailScreen extends StatelessWidget {
  final String reportId;

  const ReportDetailScreen({
    super.key,
    required this.reportId,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize =
    LayoutHelper.getSizeCategory(MediaQuery.of(context).size.width);
    final isMobile = screenSize == ScreenSizeCategory.small;

    final reportRef =
    FirebaseFirestore.instance.collection('peacefulReports').doc(reportId);

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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("No report found."));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;

          if (data == null) {
            return const Center(child: Text("Report data is empty."));
          }

          final type = data['type'] ?? 'unknown';
          final title = data['eventId'] ?? 'Unknown Event';
          final message = data['description'] ?? 'No description available.';
          final xp = data['xp'];
          final combatIdValue = data['combatId'];

          if (type == 'combat') {
            if (combatIdValue != null) {
              return CombatLogScreen(combatId: combatIdValue);
            } else {
              return const Center(
                  child: Text("⚠️ No combat ID found in report."));
            }
          }

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
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
