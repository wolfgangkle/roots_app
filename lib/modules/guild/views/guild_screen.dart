import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roots_app/modules/profile/models/user_profile_model.dart';
import 'package:roots_app/modules/profile/views/guild_profile_screen.dart';

class GuildScreen extends StatelessWidget {
  const GuildScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<UserProfileModel>();

    if (profile.guildId == null) {
      return const Center(
        child: Text("You are not in a guild."),
      );
    } else {

      return GuildProfileScreen(guildId: profile.guildId!);
    }
  }
}
