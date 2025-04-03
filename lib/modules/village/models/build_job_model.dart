import 'package:cloud_firestore/cloud_firestore.dart';

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
      durationSeconds: data['durationSeconds'] ?? 300, // defaulting to 300 seconds (5 minutes)
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

  /// Returns the expected finish time of this job
  DateTime get finishTime => startedAt.add(Duration(seconds: durationSeconds));

  /// Returns true if job is already completed
  bool get isComplete => DateTime.now().isAfter(finishTime);

  /// Convenience getter to obtain the Duration object
  Duration get duration => Duration(seconds: durationSeconds);
}
