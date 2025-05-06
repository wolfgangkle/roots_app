import 'package:flutter/foundation.dart';

class UserProfileModel with ChangeNotifier {
  final String heroName;
  final String? guildId;
  final String? guildRole;
  final String? allianceId;
  final String? allianceRole;

  UserProfileModel({
    required this.heroName,
    this.guildId,
    this.guildRole,
    this.allianceId,
    this.allianceRole,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      heroName: json['heroName'] ?? '🧙 Nameless',
      guildId: json['guildId'],
      guildRole: json['guildRole'],
      allianceId: json['allianceId'],
      allianceRole: json['allianceRole'],
    );
  }
}
