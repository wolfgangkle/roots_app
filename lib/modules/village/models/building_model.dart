class BuildingModel {
  final String type;
  final int level;

  BuildingModel({
    required this.type,
    required this.level,
  });

  factory BuildingModel.fromMap(String type, Map<String, dynamic> data) {
    return BuildingModel(
      type: type,
      level: data['level'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'level': level,
    };
  }
}
