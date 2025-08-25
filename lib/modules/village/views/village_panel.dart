import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:roots_app/modules/village/services/village_service.dart';
import 'package:roots_app/modules/village/models/village_model.dart';
import 'package:roots_app/modules/village/widgets/village_card.dart';

// 🔷 Tokens
import 'package:roots_app/theme/app_style_manager.dart';
import 'package:roots_app/theme/widgets/token_panels.dart';
import 'package:roots_app/theme/tokens.dart';

class VillagePanel extends StatefulWidget {
  final void Function(VillageModel)? onVillageTap;

  const VillagePanel({super.key, this.onVillageTap});

  @override
  VillagePanelState createState() => VillagePanelState();
}

class VillagePanelState extends State<VillagePanel> {
  final VillageService service = VillageService();

  @override
  Widget build(BuildContext context) {
    // 🔄 Live-reactive tokens
    context.watch<StyleManager>();
    final GlassTokens glass = kStyle.glass;
    final TextOnGlassTokens text = kStyle.textOnGlass;
    final EdgeInsets cardPad = kStyle.card.padding;

    return StreamBuilder<List<VillageModel>>(
      stream: service.getVillagesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Padding(
            padding: EdgeInsets.fromLTRB(cardPad.left, 12, cardPad.right, cardPad.bottom),
            child: TokenPanel(
              glass: glass,
              text: text,
              padding: EdgeInsets.fromLTRB(cardPad.left, 14, cardPad.right, 14),
              child: Text("Error: ${snapshot.error}", style: TextStyle(color: text.secondary)),
            ),
          );
        }

        final villages = snapshot.data ?? [];
        if (villages.isEmpty) {
          return Padding(
            padding: EdgeInsets.fromLTRB(cardPad.left, 12, cardPad.right, cardPad.bottom),
            child: TokenPanel(
              glass: glass,
              text: text,
              padding: EdgeInsets.fromLTRB(cardPad.left, 14, cardPad.right, 14),
              child: Text("You don’t have any villages yet.", style: TextStyle(color: text.secondary)),
            ),
          );
        }

        return ListView.separated(
          padding: EdgeInsets.fromLTRB(cardPad.left, 12, cardPad.right, cardPad.bottom),
          itemCount: villages.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final village = villages[index];
            return VillageCard(
              village: village,
              onTap: () => widget.onVillageTap?.call(village),
            );
          },
        );
      },
    );
  }
}
