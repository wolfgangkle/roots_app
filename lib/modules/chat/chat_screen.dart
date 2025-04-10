import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roots_app/modules/chat/chat_panel.dart';
import 'package:roots_app/profile/models/user_profile_model.dart';

class ChatScreen extends StatelessWidget {
  ChatScreen({super.key}); // Not const due to Provider usage

  @override
  Widget build(BuildContext context) {
    debugPrint('[ChatScreen] build() called');

    final userProfile = Provider.of<UserProfileModel>(context, listen: false);

    return ChatPanel(currentUserName: userProfile.heroName);
  }
}
