import 'package:cloud_firestore/cloud_firestore.dart';


class HeroGroupModel {
  final String id;
  final int tileX;
  final int tileY;
  final String tileKey;
  final bool insideVillage;
  final int movementSpeed;
  final List<Map<String, dynamic>> movementQueue;
  final Map<String, dynamic>? currentStep;
  final DateTime? arrivesAt;
  final List<String> members;
  final String? leaderHeroId;

  HeroGroupModel({
    required this.id,
    required this.tileX,
    required this.tileY,
    required this.tileKey,
    required this.insideVillage,
    required this.movementSpeed,
    required this.movementQueue,
    required this.currentStep,
    required this.arrivesAt,
    required this.members,
    this.leaderHeroId,
  });

  factory HeroGroupModel.fromFirestore(String id, Map<String, dynamic> data) {
    return HeroGroupModel(
      id: id,
      tileX: data['tileX'] ?? 0,
      tileY: data['tileY'] ?? 0,
      tileKey: data['tileKey'] ?? '${data['tileX']}_${data['tileY']}',
      insideVillage: data['insideVillage'] ?? false,
      movementSpeed: data['movementSpeed'] ?? 60,
      movementQueue: List<Map<String, dynamic>>.from(data['movementQueue'] ?? []),
      currentStep: data['currentStep'] != null
          ? Map<String, dynamic>.from(data['currentStep'])
          : null,
      arrivesAt: (data['arrivesAt'] as Timestamp?)?.toDate(),
      members: List<String>.from(data['members'] ?? []),
      leaderHeroId: data['leaderHeroId'],
    );
  }
}
