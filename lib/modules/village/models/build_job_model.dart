import 'package:cloud_firestore/cloud_firestore.dart';

/// 🏗️ Represents an ongoing building upgrade in a village.
/// This model is now read-only and should not trigger logic client-side.
/// All state changes are handled by backend Cloud Functions.
class BuildJobModel {
  final String buildingType;
  final int targetLevel;
  final DateTime startedAt;
  final int durationSeconds;

  BuildJobModel({
    required this.buildingType,
    required this.targetLevel,
    required this.startedAt,
    required this.durationSeconds,
  });

  factory BuildJobModel.fromMap(Map<String, dynamic> data) {
    return BuildJobModel(
      buildingType: data['buildingType'],
      targetLevel: data['targetLevel'] ?? 1,
      startedAt: (data['startedAt'] as Timestamp).toDate(),
      durationSeconds: data['durationSeconds'] ?? 300,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'buildingType': buildingType,
      'targetLevel': targetLevel,
      'startedAt': Timestamp.fromDate(startedAt),
      'durationSeconds': durationSeconds,
    };
  }

  /// 🕒 Returns the expected finish time of this upgrade job.
  DateTime get finishTime => startedAt.add(Duration(seconds: durationSeconds));

  /// ✅ UI-Only: Use this to visually display progress.
  /// Do NOT use it to control upgrade completion logic.
  bool get isComplete => DateTime.now().isAfter(finishTime);

  /// ⏳ Returns the total upgrade duration as a Duration object.
  Duration get duration => Duration(seconds: durationSeconds);

  /// ⌛ Returns time remaining (can be negative if finished).
  Duration get remaining => finishTime.difference(DateTime.now());
}
