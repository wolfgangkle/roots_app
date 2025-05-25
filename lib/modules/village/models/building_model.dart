class BuildingModel {
  final String type;
  final int level;
  final int assignedWorkers;

  BuildingModel({
    required this.type,
    required this.level,
    this.assignedWorkers = 0,
  });

  factory BuildingModel.fromMap(String type, Map<String, dynamic> data) {
    return BuildingModel(
      type: type,
      level: data['level'] ?? 1,
      assignedWorkers: data['assignedWorkers'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'level': level,
      if (assignedWorkers > 0) 'assignedWorkers': assignedWorkers,
    };
  }
}
