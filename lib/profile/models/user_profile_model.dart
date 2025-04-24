import 'package:flutter/foundation.dart';

class UserProfileModel with ChangeNotifier {
  final String heroName;
  final String? guildId;
  final String? guildRole;

  UserProfileModel({
    required this.heroName,
    this.guildId,
    this.guildRole,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      heroName: json['heroName'] ?? '🧙 Nameless',
      guildId: json['guildId'],
      guildRole: json['guildRole'],
    );
  }
}
