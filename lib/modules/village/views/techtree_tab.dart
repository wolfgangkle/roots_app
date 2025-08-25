import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 🔷 Tokens
import 'package:roots_app/theme/app_style_manager.dart';
import 'package:roots_app/theme/widgets/token_panels.dart';
import 'package:roots_app/theme/tokens.dart';

class TechtreeTab extends StatelessWidget {
  const TechtreeTab({super.key});

  @override
  Widget build(BuildContext context) {
    // 🔄 Live-reactive tokens
    context.watch<StyleManager>();
    final GlassTokens glass = kStyle.glass;
    final TextOnGlassTokens text = kStyle.textOnGlass;
    final EdgeInsets cardPad = kStyle.card.padding;

    return ListView(
      padding: EdgeInsets.fromLTRB(cardPad.left, 12, cardPad.right, cardPad.bottom),
      children: [
        // Header panel
        TokenPanel(
          glass: glass,
          text: text,
          padding: EdgeInsets.fromLTRB(cardPad.left, 14, cardPad.right, 14),
          child: Text(
            "🏗️ Village Techtree",
            style: TextStyle(
              color: text.primary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 🛖 Hut
        _sectionPanel(
          title: "🛖 Hut",
          glass: glass,
          text: text,
          cardPad: cardPad,
          children: [
            _buildLine("Level 2 Lookout Post", text, indent: 1),
            _buildLine("Level 1 Camouflage Wall", text, indent: 2),
            _buildLine("Level 3 Quarry", text, indent: 1),
            _buildLine("Level 3 Stone Storage", text, indent: 2),
            _buildLine("Level 4 Stone Bunker", text, indent: 2),
            _buildLine("Level 21 Palisade", text, indent: 2),
            _buildLine("Level 3 Academy of Arts (Ice Hail)", text, indent: 1),
            _buildLine("Level 3 Academy of Arts (Ice Lance)", text, indent: 1),
            _buildLine("Level 5 Trade Cart", text, indent: 1),
            _buildLine("Level 12 House", text, indent: 1),
            _buildLine("Level 2 Steward", text, indent: 2),
            _buildLine("Level 3 Academy of Arts (Haste)", text, indent: 2),
            _buildLine("Level 3 Academy of Arts (Icy Hand)", text, indent: 2),
            _buildLine("Level 4 Storage Room", text, indent: 2),
            _buildLine("Level 5 Transporter", text, indent: 2),
            _buildLine("Level 6 Academy of Arts (Frost Golem Summoning)", text, indent: 2),
          ],
        ),
        const SizedBox(height: 12),

        // 🌲 Wood Cutter
        _sectionPanel(
          title: "🌲 Wood Cutter",
          glass: glass,
          text: text,
          cardPad: cardPad,
          children: [
            _buildLine("Level 3 Wood Storage", text, indent: 1),
            _buildLine("Level 4 Wood Bunker", text, indent: 1),
            _buildLine("Level 6 Organization House", text, indent: 1),
            _buildLine("Level 4 Castle Complex", text, indent: 2),
            _buildLine("Level 1 Castle Moat", text, indent: 3),
            _buildLine("Level 2 Small Watchtower", text, indent: 3),
            _buildLine("Level 2 Barracks", text, indent: 3),
            _buildLine("Level 4 Watchtower", text, indent: 3),
            _buildLine("Level 5 Castle Wall", text, indent: 3),
            _buildLine("Level 7 Large Watchtower", text, indent: 3),
            _buildLine("Level 8 Architect's House", text, indent: 2),
            _buildLine("Level 10 Marketplace", text, indent: 2),
            _buildLine("Level 4 Coin Stash", text, indent: 3),
            _buildLine("Level 10 Tanner", text, indent: 1),
          ],
        ),
        const SizedBox(height: 12),

        // ⛏️ Iron Mine
        _sectionPanel(
          title: "⛏️ Iron Mine",
          glass: glass,
          text: text,
          cardPad: cardPad,
          children: [
            _buildLine("Level 3 Iron Storage", text, indent: 1),
            _buildLine("Level 4 Iron Bunker", text, indent: 1),
            _buildLine("Level 7 Blacksmith", text, indent: 1),
            _buildLine("Level 2 Armory", text, indent: 2),
            _buildLine("Level 5 Weapon Smith", text, indent: 2),
            _buildLine("Level 6 Armor Smith", text, indent: 2),
            _buildLine("Level 8 Production Manager", text, indent: 1),
            _buildLine("Level 9 Forge", text, indent: 1),
            _buildLine("Level 12 Workshop", text, indent: 1),
            _buildLine("Level 2 Laboratory", text, indent: 2),
            _buildLine("Level 3 Alchemist", text, indent: 3),
            _buildLine("Level 5 Herb Chamber", text, indent: 3),
            _buildLine("Level 8 Greenhouse", text, indent: 3),
          ],
        ),
        const SizedBox(height: 12),

        // 🌾 Farm
        _sectionPanel(
          title: "🌾 Farm",
          glass: glass,
          text: text,
          cardPad: cardPad,
          children: [
            _buildLine("Level 3 Healer's Hut", text, indent: 1),
            _buildLine("Level 4 Granary", text, indent: 1),
            _buildLine("Level 6 Grain Bunker", text, indent: 1),
            _buildLine("Level 7 Wheat Fields", text, indent: 1),
            _buildLine("Level 30 Large Wheat Fields", text, indent: 2),
          ],
        ),
      ],
    );
  }

  // ==== tokenized helpers ====

  Widget _sectionPanel({
    required String title,
    required GlassTokens glass,
    required TextOnGlassTokens text,
    required EdgeInsets cardPad,
    required List<Widget> children,
  }) {
    return TokenPanel(
      glass: glass,
      text: text,
      padding: EdgeInsets.fromLTRB(cardPad.left, 14, cardPad.right, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Text(
            title,
            style: TextStyle(
              color: text.primary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildLine(String label, TextOnGlassTokens text, {int indent = 0}) {
    final bool isRoot = indent == 0;
    final Color labelColor = isRoot ? text.primary : text.secondary;
    final double top = isRoot ? 6 : 2;

    return Padding(
      padding: EdgeInsets.only(left: indent * 16.0, top: top, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (indent > 0)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                "↳",
                style: TextStyle(
                  color: text.subtle,
                  fontSize: 14,
                ),
              ),
            ),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: labelColor,
                fontWeight: isRoot ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
