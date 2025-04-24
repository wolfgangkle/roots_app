import 'package:flutter/material.dart';

class BrowseGuildsPlaceholder extends StatelessWidget {
  const BrowseGuildsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "🛠 Browse Guilds will be available soon!\nFor now, ask your friends for an invite 😉",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}
