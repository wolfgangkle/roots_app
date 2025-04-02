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

  int get productionPerHour {
    // simple placeholder logic
    switch (type) {
      case 'woodcutter':
        return 100 * level;
      case 'quarry':
        return 80 * level;
      case 'farm':
        return 120 * level;
      default:
        return 0;
    }
  }
}
