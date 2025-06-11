import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roots_app/modules/combat/views/combat_log_screen.dart';
import 'package:roots_app/modules/combat/views/combat_log_view.dart' as logview;
import 'package:roots_app/screens/helpers/layout_helper.dart';


class ReportDetailScreen extends StatelessWidget {
  final String reportId;
  final String type; // 👈 added

  const ReportDetailScreen({
    super.key,
    required this.reportId,
    required this.type, // 👈 added
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = LayoutHelper.getSizeCategory(MediaQuery.of(context).size.width);
    final isMobile = screenSize == ScreenSizeCategory.small;

    final collection = switch (type) {
      'combat' => 'combats',
      'peaceful' => 'peacefulReports',
      _ => 'peacefulReports', // fallback default
    };

    final reportRef = FirebaseFirestore.instance.collection(collection).doc(reportId);

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

          final title = data['eventId'] ?? 'Unknown Event';
          final message = data['description'] ?? 'No description available.';
          final xp = data['xp'];
          final combatIdValue = type == 'combat'
              ? reportId // direct combat doc
              : (data['combatId'] ?? null); // linked combat from peaceful report

          return SingleChildScrollView(
            child: Padding(
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
                  const SizedBox(height: 24),
                  if (combatIdValue != null) ...[
                    const Divider(),
                    const Text("⚔️ Combat Log", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    logview.CombatLogView(combatId: combatIdValue),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
