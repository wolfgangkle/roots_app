// lib/screens/reports/report_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import 'package:roots_app/modules/combat/views/combat_log_view.dart' as logview;
import 'package:roots_app/screens/helpers/layout_helper.dart';
import 'package:roots_app/theme/app_style_manager.dart';
import 'package:roots_app/theme/widgets/token_panels.dart';

class ReportDetailScreen extends StatelessWidget {
  final String reportId;
  final String type;

  const ReportDetailScreen({
    super.key,
    required this.reportId,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final style = context.watch<StyleManager>().currentStyle;
    final text = style.textOnGlass;

    final screenSize = LayoutHelper.getSizeCategory(MediaQuery.of(context).size.width);
    final isMobile = screenSize == ScreenSizeCategory.small;

    final collection = switch (type) {
      'combat' => 'combats',
      'peaceful' => 'peacefulReports',
      _ => 'peacefulReports',
    };

    final reportRef = FirebaseFirestore.instance.collection(collection).doc(reportId);

    return Scaffold(
      backgroundColor: Colors
          .transparent, // 👈 prevent the white scaffold layer so your global bg shows
      // (no AppBar)
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

          final title = (data['eventTitle'] ?? data['eventId'] ?? 'Unknown Event').toString();
          final message = (data['description'] ?? 'No description available.').toString();
          final xp = data['xp'];
          final combatIdValue = type == 'combat' ? reportId : (data['combatId']);

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header row (transparent)
                  Row(
                    children: [
                      if (isMobile && Navigator.canPop(context))
                        IconButton(
                          icon: Icon(Icons.arrow_back, color: text.primary),
                          onPressed: () => Navigator.of(context).pop(),
                          tooltip: 'Back',
                        ),
                      const SizedBox(width: 4),
                      Text(
                        'Report Details',
                        style: TextStyle(
                          color: text.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Title
                  Text(
                    title,
                    style: TextStyle(
                      color: text.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Description (token panel for readability)
                  if (message.isNotEmpty)
                    TokenPanel(
                      glass: style.glass,
                      text: text,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      borderRadius: style.radius.card.toDouble(),
                      child: Text(
                        message,
                        style: TextStyle(
                          color: text.secondary,
                          height: 1.25,
                        ),
                      ),
                    ),

                  if (xp != null) ...[
                    const SizedBox(height: 12),
                    Text("⭐ Gained XP: $xp", style: TextStyle(color: text.primary)),
                  ],

                  const SizedBox(height: 16),

                  if (combatIdValue != null) ...[
                    Text(
                      "⚔️ Combat Log",
                      style: TextStyle(
                        color: text.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
