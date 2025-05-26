import 'package:flutter/material.dart';

class TechtreeTab extends StatelessWidget {
  const TechtreeTab({super.key});

  Widget _buildLine(String label, {int indent = 0}) {
    return Padding(
      padding: EdgeInsets.only(left: indent * 16.0, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (indent > 0) Text("↳ ", style: TextStyle(color: Colors.grey[600])),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: indent == 0 ? Colors.black : Colors.grey[800],
                fontWeight: indent == 0 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("🏗️ Village Techtree", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),

        // 🛖 Hut
        _buildLine("🛖 Hut"),
        _buildLine("Level 2 Lookout Post", indent: 1),
        _buildLine("Level 1 Camouflage Wall", indent: 2),
        _buildLine("Level 3 Quarry", indent: 1),
        _buildLine("Level 3 Stone Storage", indent: 2),
        _buildLine("Level 4 Stone Bunker", indent: 2),
        _buildLine("Level 21 Palisade", indent: 2),
        _buildLine("Level 3 Academy of Arts (Ice Hail)", indent: 1),
        _buildLine("Level 3 Academy of Arts (Ice Lance)", indent: 1),
        _buildLine("Level 5 Trade Cart", indent: 1),
        _buildLine("Level 12 House", indent: 1),
        _buildLine("Level 2 Steward", indent: 2),
        _buildLine("Level 3 Academy of Arts (Haste)", indent: 2),
        _buildLine("Level 3 Academy of Arts (Icy Hand)", indent: 2),
        _buildLine("Level 4 Storage Room", indent: 2),
        _buildLine("Level 5 Transporter", indent: 2),
        _buildLine("Level 6 Academy of Arts (Frost Golem Summoning)", indent: 2),

        const SizedBox(height: 16),

        // 🌲 Wood Cutter
        _buildLine("🌲 Wood Cutter"),
        _buildLine("Level 3 Wood Storage", indent: 1),
        _buildLine("Level 4 Wood Bunker", indent: 1),
        _buildLine("Level 6 Organization House", indent: 1),
        _buildLine("Level 4 Castle Complex", indent: 2),
        _buildLine("Level 1 Castle Moat", indent: 3),
        _buildLine("Level 2 Small Watchtower", indent: 3),
        _buildLine("Level 2 Barracks", indent: 3),
        _buildLine("Level 4 Watchtower", indent: 3),
        _buildLine("Level 5 Castle Wall", indent: 3),
        _buildLine("Level 7 Large Watchtower", indent: 3),
        _buildLine("Level 8 Architect's House", indent: 2),
        _buildLine("Level 10 Marketplace", indent: 2),
        _buildLine("Level 4 Coin Stash", indent: 3),
        _buildLine("Level 10 Tanner", indent: 1),

        const SizedBox(height: 16),

        // ⛏️ Iron Mine
        _buildLine("⛏️ Iron Mine"),
        _buildLine("Level 3 Iron Storage", indent: 1),
        _buildLine("Level 4 Iron Bunker", indent: 1),
        _buildLine("Level 7 Blacksmith", indent: 1),
        _buildLine("Level 2 Armory", indent: 2),
        _buildLine("Level 5 Weapon Smith", indent: 2),
        _buildLine("Level 6 Armor Smith", indent: 2),
        _buildLine("Level 8 Production Manager", indent: 1),
        _buildLine("Level 9 Forge", indent: 1),
        _buildLine("Level 12 Workshop", indent: 1),
        _buildLine("Level 2 Laboratory", indent: 2),
        _buildLine("Level 3 Alchemist", indent: 3),
        _buildLine("Level 5 Herb Chamber", indent: 3),
        _buildLine("Level 8 Greenhouse", indent: 3),

        const SizedBox(height: 16),

        // 🌾 Farm
        _buildLine("🌾 Farm"),
        _buildLine("Level 3 Healer's Hut", indent: 1),
        _buildLine("Level 4 Granary", indent: 1),
        _buildLine("Level 6 Grain Bunker", indent: 1),
        _buildLine("Level 7 Wheat Fields", indent: 1),
        _buildLine("Level 30 Large Wheat Fields", indent: 2),
      ],
    );
  }
}
